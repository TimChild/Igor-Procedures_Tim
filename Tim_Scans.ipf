/////////////// Checking Noise /////////////////
function standardNoiseMeasurement(ca_amp_setting, [instrID, channel, comments, nosave])
	// Run standard noise measurement (i.e. 5x 12s scans with fastdac reading 12kHz)
	// ca_amp_setting = amplification on current amp (i.e. for 1e8 enter 8)
	variable ca_amp_setting, instrID, channel, nosave
	string comments
	
	if(paramIsDefault(instrID))
		nvar fd
		instrID = fd
	endif
	channel = paramIsDefault(channel) ? 0 : channel
	comments = selectString(paramIsDefault(comments), comments, "")
	
	variable current_freq = getFADCspeed(instrID)
	setFADCSpeed(instrID, 12195)
	FDacSpectrumAnalyzer(instrID,num2str(channel),12,numAverage=5,comments="noise, spectrum, "+comments, ca_amp=ca_amp_setting, nosave=nosave)
	setFADCSpeed(instrID, current_freq)
end


function QpcStabilitySweeps()
	// 30 mins of slow sweeping down to pinch off and back to depletion to check QPC is stable (taking 90s per sweep, 10 back and forth sweeps)
	nvar fd
	variable pinchoff = -450
	variable depletion = -50
	
	ScanfastDACRepeat(fd, depletion, pinchoff, "CSQ,CSS", 20, sweeprate=abs(depletion-pinchoff)/90, alternate=1, comments="repeat, alternating, checking stability of CS gates", nosave=0)
	rampmultipleFDAC(fd, "CSQ,CSS", 0)
end



function NoiseOnOffTranisiton()

	nvar fd
	variable mid
	ScanFastDAC(fd, -100, -180, "CSQ", sweeprate=20, comments="QPC trace before On/Off transition", nosave=0)
	rampMultipleFDAC(fd, "CSQ", -155)
	variable i
	for (i=0; i<30; i++)
		mid = CenterOnTransition(gate="ACC*400", width=500, single_only=1)
		printf "Center of transition at ACC*400 = %.2f\r", mid
		asleep(3)
		FDacSpectrumAnalyzer(fd,"0",30,numAverage=1,comments="noise, spectrum, On Transition", ca_amp=8)
		rampmultipleFDAC(fd, "ACC*400", mid-500)
		asleep(3)
		FDacSpectrumAnalyzer(fd,"0",30,numAverage=1,comments="noise, spectrum, Off Transition", ca_amp=8)
		rampmultipleFDAC(fd, "ACC*400", mid)
	endfor	
	
	ScanFastDAC(fd, -100, -180, "CSQ", sweeprate=20, comments="QPC trace after On/Off transition", nosave=0)
	rampMultipleFDAC(fd, "CSQ", -155)
end


/////////////// Dot Tuning Stuff ///////////////
function checkPinchOffs(instrID, channels, gate_names, ohmic_names, max_bias, [reset_zero, nosave])
	// Helpful for checking pinch offs
	// reset_zero: Whether to return gates to 0 bias at end of pinch off (defaults to True)
	variable instrID, max_bias, reset_zero, nosave
	string channels, gate_names, ohmic_names

	reset_zero = paramIsDefault(reset_zero) ? 1 : reset_zero  

	string buffer
	sprintf buffer, "Pinch off, Gates=%s, Ohmics=%s", gate_names, ohmic_names
	ScanFastDAC(instrID, 0, max_bias, channels, sweeprate=300, x_label=gate_names+" /mV", y_label="Current /nA", comments=buffer, nosave=nosave)	
	if (reset_zero)
		rampmultiplefdac(instrID, channels, 0)
	endif
end


function DotTuneAround(x, y, width_x, width_y, channelx, channely, [sweeprate, ramprate_x, numptsy, csname])
// Goes to x, y. Sets charge sensor to target_current. Scans2D around x, y +- width.
	variable x, y, width_x, width_y, ramprate_x
	variable sweeprate, numptsy
	string channelx, channely, csname
	
	variable natarget = 1630//595//750//287 //1335   // ADC reading in mV to get most sensitive part of CS
	sweeprate = paramisdefault(sweeprate) ? 300 : sweeprate
	numptsy = paramisdefault(numptsy) ? 21 : numptsy
	csname = selectstring(paramisdefault(csname), csname, "CSQ")
	ramprate_x = paramisdefault(ramprate_x) ? 1000 : ramprate_x
	
	
	nvar fd
	rampmultiplefdac(fd, channelx, x, ramprate=ramprate_x)
	rampmultiplefdac(fd, channely, y)
	
	CorrectChargeSensor(fd=fd, fdchannelstr=csname, fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1)
	ScanFastDAC2D(fd, x-width_x, x+width_x, channelx, y-width_y, y+width_y, channely, numptsy, sweeprate=sweeprate, rampratex=ramprate_x, nosave=0, comments="Dot Tuning")
	wave tempwave = $"cscurrent_2d"
	nvar filenum
	displaydiff(tempwave, filenum=filenum-1, x_label=GetLabel(SF_get_channels(channelx, fastdac=1), fastdac=1), y_label=GetLabel(SF_get_channels(channely, fastdac=1), fastdac=1))
end


// Generally Useful Scan Functions
function StepTempScanSomething()
	nvar fd
	svar ls370

	make/o targettemps =  {300, 275, 250, 225, 200, 175, 150, 125, 100, 75, 50, 40, 30, 20}
//	make/o targettemps =  {300, 250, 200, 150, 100, 75, 50, 35}
	setLS370exclusivereader(ls370,"mc")

	variable width
	variable i=0
	do
		setLS370temp(ls370,targettemps[i])
		asleep(2.0)
		WaitTillTempStable(ls370, targettemps[i], 5, 20, 0.10)
		asleep(60.0)
		print "MEASURE AT: "+num2str(targettemps[i])+"mK"

		// Scan Goes here
		width = max(100, 4*targettemps[i])
		ScanTransition(sweeprate=width/5, width=width, repeats=100, center_first=1, center_gate="ACC*2", center_width=10, sweep_gate="ACC*400", csqpc_gate="CSQ", additional_comments="Temp = " + num2str(targettemps[i]) + " mK")
		//////////////////////
		i+=1
	while ( i<numpnts(targettemps) )

	// kill temperature control
//	setLS370heaterOff(ls370)
	setLS370temp(ls370,10)
	resetLS370exclusivereader(ls370)
	asleep(60.0*60)

	// Base T Scan goes here
	width = 100
	ScanTransition(sweeprate=width/5, width=width, repeats=100, center_first=1, center_gate="ACC*2", center_width=10, sweep_gate="ACC*400", csqpc_gate="CSQ", additional_comments="Temp = 10 mK")
	/////////////////////////////////
end


function ScanEntropyRepeat([num, center_first, balance_multiplier, width, hqpc_bias, additional_comments, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center])
	variable num, center_first, balance_multiplier, width, hqpc_bias, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center
	string additional_comments
	nvar fd
	
	num = paramisdefault(num) ? 										INF : num
	center_first = paramisdefault(center_first) ? 				0 : center_first
	balance_multiplier = paramisdefault(balance_multiplier) ? 	1 : balance_multiplier
	hqpc_bias = paramisdefault(hqpc_bias) ? 						50 : hqpc_bias
	repeat_multiplier = paramisDefault(repeat_multiplier) ? 	1 : repeat_multiplier
	sweeprate = paramisdefault(sweeprate) ? 						10 : sweeprate
	freq = paramisdefault(freq) ? 									12.5 : freq
	two_part = paramisdefault(two_part) ? 							0 : two_part
	center = paramisdefault(center) ? 								0 : center

	if (two_part == 1 && !paramisdefault(repeats))
		abort "repeats is only meant to be set for a one part scan, not two part"
	endif
	
	variable nosave = 0
	
	variable width1 = paramisdefault(width) ? 1000 : width
	variable width2 = width1/3
	variable repeats1 = 2*repeat_multiplier
	variable repeats2 = 30*repeat_multiplier
	string comments = "transition, square entropy, repeat, "
	if (!paramisdefault(additional_comments))
		sprintf comments, "%s%s, ", comments, additional_comments
	endif
	
	variable splus = hqpc_bias, sminus=-hqpc_bias	
	SetupEntropySquareWaves(freq=freq, cycles=1, hqpc_plus=splus, hqpc_minus=sminus, balance_multiplier=balance_multiplier)

//	variable cplus=-splus*0.031 * balance_multiplier, cminus=-sminus*0.031 * balance_multiplier
//	SetupEntropySquareWaves_unequal(freq=freq, hqpc_plus=splus, hqpc_minus=sminus, balance_multiplier=balance_multiplier)

	variable mid, r
	if (center_first)
		rampmultiplefdac(fd, "ACC/100", center)
		centerontransition(gate="ESP", width=30)
		rampmultiplefdac(fd, "ACC/100", center-200)
		if (!paramisdefault(cs_target))
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=cs_target)		
		else
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)		
		endif
		rampmultiplefdac(fd, "ACC/100", center)
		mid = centerontransition(gate="ACC/100", width=200, single_only=1)
		if (numtype(mid) == 2)
			mid = center
		endif
	else
		mid = center
	endif
	
	variable i=0
	do
		if(paramisdefault(num))
			printf "Starting scan %d of \u221E\r", i
		else
			printf "Starting scan %d of %d\r", i, num
		endif 	
		if (two_part == 1)
			ScanFastDACrepeat(fd, mid-width1, mid+width1, "ACC/100", repeats1, sweeprate=sweeprate, delay=0.2, comments=comments+", part1of2", use_awg=1, nosave=nosave)							
			ScanFastDACrepeat(fd, mid-width2, mid+width2, "ACC/100", repeats2, sweeprate=sweeprate, delay=0.2, comments=comments+", part2of2", use_awg=1, nosave=nosave)			
		else
			if (!paramisDefault(repeats) && repeats > 0)
				r = repeats
			else
				r = repeats2
			endif
			ScanFastDACrepeat(fd, mid-width1, mid+width1, "ACC/100", r, sweeprate=sweeprate, delay=0.2, comments=comments, use_awg=1, nosave=nosave)						
		endif
		rampmultiplefdac(fd, "ACC/100", mid)	
		i++
	while (i<num)
end


function ScanTransition([sweeprate, width, ramprate, repeats, center_first, center_gate, center_width, sweep_gate, additional_comments, sweepgate_mid, csqpc_gate])
	variable sweeprate, width, ramprate, repeats, center_first, center_width, sweepgate_mid
	string center_gate, sweep_gate, additional_comments, csqpc_gate
	nvar fd
	
	sweeprate = paramisdefault(sweeprate) ? 100 : sweeprate
	width = paramisdefault(width) ? 200 : width
	ramprate = paramisDefault(ramprate) ? 1000 : ramprate
	repeats = paramIsDefault(repeats) ? 10 : repeats
	sweepgate_mid = paramIsDefault(sweepgate_mid) ? 0 : sweepgate_mid
	// let center_first default to 0
	sweep_gate = selectstring(paramisdefault(sweep_gate), sweep_gate, "ACC/100")
	center_gate = selectstring(paramisdefault(center_gate), center_gate, "ESP")
	center_width = paramisDefault(center_width) ? 50 : center_width
	additional_comments = selectstring(paramisdefault(additional_comments), additional_comments, "")
	csqpc_gate = selectstring(paramisdefault(csqpc_gate), csqpc_gate, "CSQ")		
	
	if (center_first)
		variable center_gate_mid
		rampmultiplefdac(fd, sweep_gate, sweepgate_mid, ramprate=ramprate)  // Make sure sweep gate is at center
		CorrectChargeSensor(fd=fd, fdchannelstr=csqpc_gate, fadcID=fd, fadcchannel=0, check=0, direction=1)  // Initial CS correction
		center_gate_mid = centerontransition(gate=center_gate, width=center_width, single_only=1)  // Initial center
		rampmultiplefdac(fd, sweep_gate, -width*0.5, ramprate=ramprate)	 // Move off transition
		CorrectChargeSensor(fd=fd, fdchannelstr=csqpc_gate, fadcID=fd, fadcchannel=0, check=0, direction=1)  // Correct CS close to center
		rampmultiplefdac(fd, sweep_gate, sweepgate_mid, ramprate=ramprate)	// Go back to center of sweepgate
		center_gate_mid = centerontransition(gate=center_gate, width=center_width, single_only=1)  // Center again after CS is corrected
		printf "Centered at %s = %.2f mV\r", center_gate, center_gate_mid
		if (cmpstr(center_gate, sweep_gate) == 0)
			sweepgate_mid = center_gate_mid
		endif
	endif
	
	ScanFastDACrepeat(fd, sweepgate_mid-width, sweepgate_mid+width, sweep_gate, repeats, sweeprate=sweeprate, ramprate=ramprate, nosave=0, delay=0.01, comments="transition, repeat" + additional_comments)
	rampmultiplefdac(fd, sweep_gate, sweepgate_mid, ramprate=ramprate)
end


function ScanTransitionNoise()
	nvar fd
	
	variable mid
	variable natarget = 738*5/3
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1)  
	rampmultiplefdac(fd, "ACC/100", 0, ramprate=10000)
	mid = centerontransition(gate="ESP", width=50, single_only=0)
	print "Centered at ESP="+num2str(mid)+"mV"
	rampmultiplefdac(fd, "ACC/100", -200, ramprate=10000)	
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1) 
	
	mid = centerontransition(gate="ACC/100", width=1000, single_only=0)
	print "Centered BEFORE at ACC/100="+num2str(mid)+"mV"
	ScanFastDAC(fd, -1199, -1201, "BDL_BD2S", numpts=761400, nosave=0, comments="readvstime, ON transition")
	mid = centerontransition(gate="ACC/100", width=1000, single_only=0)
	print "Centered AFTER at ACC/100="+num2str(mid)+"mV"
	
	rampmultiplefdac(fd, "ACC/100", -350, ramprate=10000)
	ScanFastDAC(fd, -1199, -1201, "BDL_BD2S", numpts=761400, nosave=0, comments="readvstime, OFF transition")
	
	rampmultiplefdac(fd, "ACC/100", 0, ramprate=10000)
end


function ScanTransitionMany()
	nvar fd
	
	make/o/free Var1  = {-305, -343, -430, -510, -608, -713}  // ESP
	make/o/free Var1b = {-480, -465, -430, -400, -365, -330} // ESS
	make/o/free Var2 = {0}
	make/o/free Var3 = {0,0,0,0,0,0,0,0,0,0}
	
	variable numi = numpnts(Var1), numj = numpnts(Var2), numk = numpnts(Var3)
	variable ifin = numi, jfin = numj, kfin = numk
	variable istart, jstart, kstart
	
	// Starts
	istart=0; jstart=0; kstart=0
	
	// Fins
	ifin=ifin; jfin=jfin; kfin=kfin
	
	
	string comments
	variable mid
	
	variable i, j, k, repeats
	i = istart; j=jstart; k=kstart
	for(k=kstart;k<kfin;k++)  // Loop for change k var 3
		kstart = 0 
		for(j=jstart;j<jfin;j++)	// Loop for change j var2
			jstart = 0 
			for(i=istart;i<ifin;i++) // Loop for changing i var1 and running scan
				istart = 0 
				printf "Starting scan at i=%d, ESS = %.1fmV \r", i, Var1b[i]
				rampmultiplefdac(fd, "ESP", Var1[i])
				rampmultiplefdac(fd, "ESS", Var1b[i])
				for(repeats=0;repeats<3;repeats++)
					// Do Scan here
				endfor
			endfor
		endfor
	endfor
	
	print "Finished all scans"
end





///////////////////////////////////////////////////////////////////////////////////////////
/////////////////////// MISCELLANEOUS /////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
function DCbiasRepeats(max_current, num_steps, duration, [voltage_ratio])
	// DCBias measurements with ScanFastDACRepeat at each value (rather than a continuously changing 2D plot)
	// Note: Assumes already lined up on transition
	variable max_current // Max current in nA through heater
	variable num_steps  // Number of steps from 0 -> max_current
	variable duration  // Duration of scan at each step
	variable voltage_ratio  // Proportional Voltage to use to offset potential created by current bias (all in mV from DAC)
	
	voltage_ratio = paramisDefault(voltage_ratio) ? 1.5038 : voltage_ratio
	variable current_resistor = 10 // Mohms of resistance current bias is driven through
	variable scan_width = 1000
	variable rampratex = 100000
	variable sweeprate = 2000
	string current_channel = "OHC(10M)"
	string voltage_channel = "OHV*1000"
	
	nvar fd
	string comments
	variable repeats
	
	repeats = round((duration/(scan_width*2/sweeprate)))  // Desired duration / (scan width/sweeprate)
	
	// Measure with zero bias
	rampmultipleFDAC(fd, current_channel, 0)
	rampmultipleFDAC(fd, voltage_channel, 0)
	sprintf comments, "DCbias Repeat, zero bias"
	ScanFastDACRepeat(fd, -scan_width, scan_width, "ACC*400", repeats, ramprate=rampratex, sweeprate=sweeprate, comments=comments, nosave=0)
	
	// Measure with non-zero bias
	variable setpoint
	variable i
	for (i=1; i<num_steps+1; i++)  // Start from 1 for only non-zero bias
		setpoint = i*(max_current*10/num_steps)
		
		// Measure positive bias
		rampmultipleFDAC(fd, current_channel, setpoint)
		rampmultipleFDAC(fd, voltage_channel, -setpoint*voltage_ratio)
		sprintf comments, "DCbias Repeat, %.3f nA" setpoint/current_resistor
		ScanFastDACRepeat(fd, -scan_width, scan_width, "ACC*400", repeats, ramprate=rampratex, sweeprate=sweeprate, comments=comments, nosave=0)
		
		// Measure negative bias
		rampmultipleFDAC(fd, current_channel, -setpoint)
		rampmultipleFDAC(fd, voltage_channel, setpoint*voltage_ratio)
		sprintf comments, "DCbias Repeat, %.3f nA" -setpoint/current_resistor
		ScanFastDACRepeat(fd, -scan_width, scan_width, "ACC*400", repeats, ramprate=rampratex, sweeprate=sweeprate, comments=comments, nosave=0)

	endfor

	// Return to zero heating
	rampmultipleFDAC(fd, current_channel, 0)
	rampmultipleFDAC(fd, voltage_channel, 0)
end