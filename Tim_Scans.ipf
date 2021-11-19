////////////////////// Noise Measurements ///////////////////////

function GetIntegratedNoise(channel, ca_amp, [duration])
	string channel
	variable ca_amp, duration
	duration = paramisdefault(duration) ? 1 : duration
	nvar fd
	FDacspectrumanalyzer_wave(fd,channel,duration,20,ca_amp)
	
	nvar sanum
	variable sa_num = sanum-1
	string wn = "sasavedlin" + num2str(sa_num) + "_int"
	wave intpsd = $wn
	return intpsd[numpnts(intpsd)-1]
end

//Return 0 on failure, 1 on success
function FDacSpectrumAnalyzer_wave(instrID,ch,dur,numAverage, ca_amp, [comments])
	variable instrID, ca_amp
	string ch, comments
	variable dur, numaverage
	if(paramisdefault(comments))
		comments = ""
	endif
	FDacSpectrumAnalyzer(instrId,ch,dur,numAverage = numaverage, comments=comments, ca_amp=ca_amp)
	nvar SAnum
	string SAnumstr = ""
	sprintf SAnumstr, "%d", SAnum
	string wn = "SAsaved"+ SAnumstr
	string source_wn = "fftadc" + ch
	string wn_lin = "SAsavedlin"+SAnumstr
	string source_wn_lin = "fftADClin"+ch
	DeletePoints 0,1, $source_wn
	DeletePoints 0,1, $source_wn_lin
	duplicate $source_wn $wn
	duplicate $source_wn_lin $wn_lin
	IntegrateNoise($wn_lin, dur)
	SAnum += 1
	print wn, wn_lin
	return 1
end




/////////////// Tuning Stuff ///////////////
function PinchTestBD(bd, start, fin, channels, numpts, delay, ramprate, current_wave, cutoff_nA, gates_str)
	/// For testing pinch off (10/2/2020)
	// Make sure current wave is in nA
	variable bd, start, fin, numpts, delay, ramprate, cutoff_nA
	string channels, current_wave, gates_str
	rampmultiplebd(bd, channels, 0, ramprate=ramprate)
	string comment
	sprintf comment, "pinch, gates=(%s)", gates_str
	ScanBabyDACUntil(bd, start, fin, channels, numpts, delay, ramprate, current_wave, cutoff_nA, operator="<", comments=comment)
	rampmultiplebd(bd, channels, 0, ramprate=ramprate)
end

function PinchTestFD(fd, start, fin, channels, sweeprate, gates_str, [ramprate])
	/// For testing pinch off (4/2021)
	// Make sure current wave is in nA
	variable fd, start, fin, sweeprate, ramprate
	string channels, gates_str
	
	ramprate = paramisdefault(ramprate) ? 1000 : ramprate
	
	rampmultiplefdac(fd, channels, start, ramprate=ramprate)
	string comment
	sprintf comment, "pinch, gates=(%s)", gates_str
	ScanFastdac(fd, start, fin, channels, sweeprate=sweeprate, comments=comment)
	rampmultiplefdac(fd, channels, start, ramprate=ramprate)
end


function PinchTestWithGatesSet(start, fin, numpts, [fd_channels, bd_channels])
	// For testing pinch off where all DACs are already connected. (doesn't work where one gate is on BabyDac and another is on FastDac)
	// 4/2021
	variable start, fin, numpts
	string fd_channels, bd_channels
	
	nvar fd, bd

	if (!paramisdefault(fd_channels))
		rampmultiplefdac(fd, fd_channels, start)
		ScanFastDAC(fd, start, fin, fd_channels, numpts=numpts, ramprate=2000, y_label="Current /nA", comments="Pinch, "+fd_channels)
		rampmultiplefdac(fd, fd_channels, start)
	elseif (!paramisdefault(bd_channels))
		rampmultiplebd(bd, bd_channels, start)
		ScanBabyDac(bd, start, fin, bd_channels, numpts, 0.0001, 2000, comments="Pinch, "+bd_channels)
		rampmultiplebd(bd, bd_channels, start)
	endif
end


function DotTuneAround(x, y, width_x, width_y, channelx, channely, [sweeprate, ramprate_x, numptsy, y_is_bd, csname, nosave, additional_comments])
// Goes to x, y. Sets charge sensor to target_current. Scans2D around x, y +- width.
	variable x, y, width_x, width_y, ramprate_x, nosave, y_is_bd
	variable sweeprate, numptsy
	string channelx, channely, csname, additional_comments
	
	variable natarget = 7//5.45//5.95//7.50//2.87 //1.335   // ADC reading in mV to get most sensitive part of CS
//	variable rccutoff = 1000
	sweeprate = paramisdefault(sweeprate) ? 300 : sweeprate
	numptsy = paramisdefault(numptsy) ? 21 : numptsy
	csname = selectstring(paramisdefault(csname), csname, "CSQ")
	ramprate_x = paramisdefault(ramprate_x) ? 1000 : ramprate_x
	nosave = paramisdefault(nosave) ? 0 : nosave
	additional_comments = selectstring(numtype(strlen(additional_comments)) != 0, additional_comments, "")
	
	nvar fd, bd
	rampmultiplefdac(fd, channelx, x, ramprate=ramprate_x)
	if (y_is_bd)
		rampmultiplebd(fd, channely, y)
	else
		rampmultiplefdac(fd, channely, y)
	endif
	
	CorrectChargeSensor(fd=fd, fdchannelstr=csname, fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1)
	if (y_is_bd)
		ScanFastDAC2D(fd, x-width_x, x+width_x, channelx, y-width_y, y+width_y, channely, numptsy, bdID = bd, sweeprate=sweeprate, rampratex=ramprate_x, nosave=nosave, comments="Dot Tuning"+additional_comments)
	else
		ScanFastDAC2D(fd, x-width_x, x+width_x, channelx, y-width_y, y+width_y, channely, numptsy, sweeprate=sweeprate, rampratex=ramprate_x, nosave=nosave, comments="Dot Tuning"+additional_comments)
	endif
	wave tempwave = $"cscurrent_2d"
	nvar filenum
	displaydiff(tempwave, filenum=filenum-1)
end



function DCBias()
	nvar fd, bd
	
	
	variable repeats, width, sweeprate, ramprate
	repeats = 300
	width = 2500
	sweeprate = 10000
	ramprate = 300000
	
	
//	make/o/free Var1 = {10, 20, 30, 35, 50, 100} // Heater settings
	make/o/free Var1 = {700, 800, 900, 1000} // Heater settings
//	make/o/free Var1 = {0, 25} // Heater settings	
//	make/free/o/n=10 w1 = linspace(0, 9, 10)[p]
//	make/free/o/n=8 w2 = linspace(10, 45, 8)[p]
//	make/free/o/n=6 w3 = linspace(50, 90, 5)[p]
//	make/free/o/n=10 w4 = linspace(100, 1000, 10)[p]
//	concatenate/np/o {w1, w2, w3, w4}, Var1
//	print Var1
//	make/o/free Var2 = {0, -100, -200, -400,-400,-600,-700,-800} // BD2D settings
	make/o/free Var2 = {0} 
	make/o/free Var3 = {0}

	
	variable numi = numpnts(Var1), numj = numpnts(Var2), numk = numpnts(Var3)
	variable ifin = numi, jfin = numj, kfin = numk
	variable istart, jstart, kstart
	
	
	/////// Change range of outer scan variables (useful when retaking a few measurements) ////////
	/// Starts
	istart=0; jstart=0; kstart=0
	
	/// Fins
	ifin=ifin; jfin=jfin; kfin=kfin
	////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	string comments
	variable i, j, k
	i = istart; j=jstart; k=kstart
	for(k=kstart;k<kfin;k++)  // Loop for change k var 3
		kstart = 0 
		for(j=jstart;j<jfin;j++)	// Loop for change j var2
			jstart = 0
			
			// RAMP BD2D
//			rampmultiplebd(bd, "BD2D", Var2[j])
			
			for(i=istart;i<ifin;i++) // Loop for changing i var1 and running scan
				istart = 0  // Reset for next loop if started somewhere in middle
				
				// RAMP HOs

				rampmultiplefdac(fd, "HO1/10M", Var1[i])
				rampmultiplefdac(fd, "HO2*1000", -1.531*Var1[i])
				
				printf "Starting scan at i=%d, j=%d, k=%d, Heater Current (nA) = %.1fmV, BD2D = %.1fmV, Var3 = %.1fmV\r", i, j, k, Var1[i], Var2[j], Var3[k]
				sprintf comments, ""
			
				ScanTransition(sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=0, additional_comments=", dcbias, scan:"+num2str(i))
				
				rampmultiplefdac(fd, "HO1/10M", -Var1[i])
				rampmultiplefdac(fd, "HO2*1000", 1.531*Var1[i])
				
				ScanTransition(sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=0, additional_comments=", dcbias, scan:"+num2str(i))
				
			endfor
		endfor
	endfor
	print "Finished all scans"
end


//////////////////////////// Other Useful Scans //////////////////////

function StepTempScanSomething()
	nvar fd
	svar xld

//	make/o targettemps =  {300, 275, 250, 225, 200, 175, 150, 125, 100, 75, 50, 40, 30, 20}
//	make/o targettemps =  {200, 175, 150, 125, 100, 75, 50, 40, 30, 20}
//	make/o targettemps =  {300, 250, 200, 150, 100, 75, 50, 35}
//	make/o/free targettemps =  {500, 400, 300, 200, 100, 50}
//	make/o/free hqpc_biases =  {8, 200, 100, 40,  10,  8, 	 4}	
//	make/o/free targettemps =  {50, 100, 200, 300, 400, 500}
//	make/o/free hqpc_biases =  {4,  8,   10,  40,  100, 200}

//	make/o targettemps =  {30, 20}
	make/o targettemps =  {200, 100, 50}
//	make/o heaterranges = {3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 1, 1, 1, 1}
//	make/o heaterranges = {1, 1, 0.31}
	setLS370exclusivereader(xld,"mc")


	variable i=0
	do
//		setLS370temp(xld,targettemps[i], maxcurrent=heaterranges[i])
		setLS370temp(xld,targettemps[i])
		asleep(2.0)
		WaitTillTempStable(xld, targettemps[i], 5, 20, 0.10)
		asleep(60.0)
		print "MEASURE AT: "+num2str(targettemps[i])+"mK"

//		ScanTransitionMany()
//		EntropyVsHeaterBias()
//		ScanFastDAC2D(fd, -1000, 1000, "ACC*1000", 0, 0, "HO1/10M,HO2*1000", 21, sweeprate=2000, rampratex=20000, startys="-1000,1952", finys="1000,-1952", comments="DCbias, finding heating % for various T")
//		LeverArmVsFridgeTemp(hqpc_biases[i])
//		AlongTransitionMoreSymmetric(scan_type="transition_vs_temp", fridge_temp = targettemps[i])
//		DCBias()
		AlongTransitionMoreSymmetric(scan_type="entropy weak only fast", fridge_temp=targettemps[i])
		i+=1
	while ( i<numpnts(targettemps) )

	// kill temperature control
	setLS370heaterOff(xld)
	resetLS370exclusivereader(xld)
//	asleep(60.0*60)	
	
	setls370temp(xld, 100)

//	AlongTransitionMoreSymmetric(scan_type="transition_vs_temp", fridge_temp = 30)  // Electron temp is ~30mK
//	ScanTransitionMany()
//	EntropyVsHeaterBias()

end




function ScanEntropyRepeat([num, center_first, balance_multiplier, width, hqpc_bias, additional_comments, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center, virtual_gate, virtual_mids, cycles])
	variable num, center_first, balance_multiplier, width, hqpc_bias, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center, virtual_gate, cycles
	string additional_comments, virtual_mids
	nvar fd
	
	num = paramisdefault(num) ? 										INF : num
	center_first = paramisdefault(center_first) ? 				0 : center_first
	balance_multiplier = paramisdefault(balance_multiplier) ? 	1 : balance_multiplier
	hqpc_bias = paramisdefault(hqpc_bias) ? 						50 : hqpc_bias
	repeat_multiplier = paramisDefault(repeat_multiplier) ? 	1 : repeat_multiplier
	sweeprate = paramisdefault(sweeprate) ? 						100 : sweeprate
	freq = paramisdefault(freq) ? 									12.5 : freq
	two_part = paramisdefault(two_part) ? 							0 : two_part
	center = paramisdefault(center) ? 								0 : center
	cycles = paramisdefault(cycles) ? 								1 : cycles
	
	string virtual_gates = "IP1*200"
	string ratios = "-0.0914"

	if (two_part == 1 && !paramisdefault(repeats))
		abort "repeats is only meant to be set for a one part scan, not two part"
	endif
	
	variable nosave = 0
	
	variable width1 = paramisdefault(width) ? 10000 : width
	variable width2 = width1/3
	variable repeats1 = 2*repeat_multiplier
	variable repeats2 = 30*repeat_multiplier
	string comments = "transition, square entropy, repeat, "
	if (!paramisdefault(additional_comments))
		sprintf comments, "%s%s, ", comments, additional_comments
	endif
	
	variable splus = hqpc_bias, sminus=-hqpc_bias	
	SetupEntropySquareWaves(freq=freq, cycles=cycles, hqpc_plus=splus, hqpc_minus=sminus, balance_multiplier=balance_multiplier)

//	variable cplus=-splus*0.031 * balance_multiplier, cminus=-sminus*0.031 * balance_multiplier
//	SetupEntropySquareWaves_unequal(freq=freq, hqpc_plus=splus, hqpc_minus=sminus, balance_multiplier=balance_multiplier)

	variable mid, r
	if (center_first)
		rampmultiplefdac(fd, "ACC*1000", center)
		////////////////////////////////////////////////////// 2021-04-12 temporarily disabled for ACC only scans
//		centerontransition(gate="ESP", width=50)
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		rampmultiplefdac(fd, "ACC*1000", center-2000)
		if (!paramisdefault(cs_target))
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=cs_target)		
		else
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)		
		endif
		rampmultiplefdac(fd, "ACC*1000", center)
		mid = centerontransition(gate="ACC*1000", width=10000, single_only=1)
		if (numtype(mid) == 2)
			mid = center
		endif
	else
		mid = center
	endif
	
	variable i=0
	string virtual_starts_ends
	do
		if(paramisdefault(num))
			printf "Starting scan %d of \u221E\r", i
		else
			printf "Starting scan %d of %d\r", i, num
		endif 	
		if (two_part == 1)
			ScanFastDACrepeat(fd, mid-width1, mid+width1, "ACC*1000", repeats1, sweeprate=sweeprate, delay=0.2, comments=comments+", part1of2", use_awg=1, nosave=nosave)							
			ScanFastDACrepeat(fd, mid-width2, mid+width2, "ACC*1000", repeats2, sweeprate=sweeprate, delay=0.2, comments=comments+", part2of2", use_awg=1, nosave=nosave)			
		else
			if (!paramisDefault(repeats) && repeats > 0)
				r = repeats
			else
				r = repeats2
			endif
			if (virtual_gate)
				virtual_starts_ends = get_virtual_scan_params(mid, width1, virtual_mids, ratios)
				ScanFastDACrepeat(fd, 0, 0, addlistItem(virtual_gates, "ACC*1000", ",", INF), r, starts=stringfromlist(0, virtual_starts_ends), fins=stringfromlist(1, virtual_starts_ends), sweeprate=sweeprate, delay=0.1, comments=comments, use_awg=1, nosave=nosave)			
			else
				ScanFastDACrepeat(fd, mid-width1, mid+width1, "ACC*1000", r, sweeprate=sweeprate, delay=0.1, comments=comments, use_awg=1, nosave=nosave)						
			endif
		endif
		rampmultiplefdac(fd, "ACC*1000", mid)	
		i++
	while (i<num)
end



function ScanTransition([sweeprate, width, ramprate, repeats, center_first, center_gate, center_width, sweep_gate, additional_comments, mid, cs_target, virtual_gate, virtual_mids])
	variable sweeprate, width, ramprate, repeats, center_first, center_width, mid, cs_target, virtual_gate
	string center_gate, sweep_gate, additional_comments, virtual_mids
	nvar fd
	
	string virtual_gates = "IP1*200"
	string ratios = "-0.0914"
	
	sweeprate = paramisdefault(sweeprate) ? 100 : sweeprate
	width = paramisdefault(width) ? 2000 : width
	ramprate = paramisDefault(ramprate) ? 10000 : ramprate
	repeats = paramIsDefault(repeats) ? 10 : repeats
	mid = paramIsDefault(mid) ? 0 : mid
	// let center_first default to 0
	sweep_gate = selectstring(paramisdefault(sweep_gate), sweep_gate, "ACC*1000")
	center_gate = selectstring(paramisdefault(center_gate), center_gate, "ESP")
	center_width = paramisDefault(center_width) ? 50 : center_width
	additional_comments = selectstring(paramisdefault(additional_comments), additional_comments, "")
	
	if (center_first)
		rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
		////////////////////////// Need to record mid if centering with sweep gate ///////////////////////////////////
		centerontransition(gate=center_gate, width=center_width, single_only=1)
		print "Centered at ESP="+num2str(mid)+"mV"
		rampmultiplefdac(fd, sweep_gate, -width*0.5, ramprate=ramprate)	
		if (!paramisdefault(cs_target))
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=cs_target)
		else
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)  
		endif
	endif
	
	string virtual_starts_ends
	if (virtual_gate)
		virtual_starts_ends = get_virtual_scan_params(mid, width, virtual_mids, ratios)
		ScanFastDACrepeat(fd, 0, 0, addlistItem(virtual_gates, "ACC*1000", ",", INF), repeats, starts=stringfromlist(0, virtual_starts_ends), fins=stringfromlist(1, virtual_starts_ends), sweeprate=sweeprate, ramprate=ramprate, delay=0.01, comments="transition, repeat" + additional_comments, nosave=0)			
	else
		ScanFastDACrepeat(fd, mid-width, mid+width, sweep_gate, repeats, sweeprate=sweeprate, ramprate=ramprate, delay=0.01, comments="transition, repeat" + additional_comments, nosave=0)						
	endif
//	ScanFastDACrepeat(fd, mid-width, mid+width, sweep_gate, repeats, sweeprate=sweeprate, ramprate=ramprate, nosave=0, delay=0.01, comments="transition, repeat" + additional_comments)
	rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
end

function ScanTransitionNoise()
	nvar fd
	
	variable mid
	variable natarget = 738*5/3
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1)  
	rampmultiplefdac(fd, "ACC*1000", 0, ramprate=100000)
	mid = centerontransition(gate="ESP", width=50, single_only=0)
	print "Centered at ESP="+num2str(mid)+"mV"
	rampmultiplefdac(fd, "ACC*1000", -2000, ramprate=100000)	
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1) 
	
	mid = centerontransition(gate="ACC*1000", width=10000, single_only=0)
	print "Centered BEFORE at ACC*1000="+num2str(mid)+"mV"
	ScanFastDAC(fd, -1199, -1201, "BDL_BD2S", numpts=761400, nosave=0, comments="readvstime, ON transition")
	mid = centerontransition(gate="ACC*1000", width=10000, single_only=0)
	print "Centered AFTER at ACC*1000="+num2str(mid)+"mV"
	
	rampmultiplefdac(fd, "ACC*1000", -3500, ramprate=100000)
	ScanFastDAC(fd, -1199, -1201, "BDL_BD2S", numpts=761400, nosave=0, comments="readvstime, OFF transition")
	
	rampmultiplefdac(fd, "ACC*1000", 0, ramprate=100000)
end


function ScanTransitionMany()
	nvar fd
	
//	make/o/free Var1  = {-946, -917, -901, -887, -864, -845, -819, -792}  // ESP
//	make/o/free Var1b = {-520, -530.5, -536.5, -542.5, -551.5, -559, -569.5, -581.5} // ESS
//	make/o/free Var1  = {-365, -403, -490, -570, -668, -773}  // ESP
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
					rampmultiplefdac(fd, "HO1,HO2", 0)
					rampmultiplefdac(fd, "ACC*1000", 0, ramprate=100000)
					CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)
					mid = centerontransition(gate="ESP", width=30, single_only=0)
					rampmultiplefdac(fd, "ACC*1000", -2000, ramprate=100000)	
					CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)
					GetIntegratedNoise("0", 8)
//					mid = centerontransition(gate="ESP", width=30, single_only=0)
					rampmultiplefdac(fd, "ACC*1000", 0, ramprate=100000)
					mid = centerontransition(gate="ACC*1000", width=2000, single_only=1)
					GetIntegratedNoise("0", 8)		

					ScanEntropyRepeat(center_first=1, balance_multiplier=1, width=100, hqpc_bias=50, additional_comments="entropy repeat, fairly high bias, rough scans only", freq=12.5, sweeprate=10, two_part=0, repeats=30, num=1)
//					ScanTransition()
//					asleep(600)
				endfor
			endfor
		endfor
	endfor
	
	print "Finished all scans"
end




function ScanAlongTransition(step_gate, step_size, step_range, center_gate, sweep_gate, sweeprate, repeats, width, [center_step_ratio, centering_width, center_sweep_gate, scan_type, correct_cs_gate, sweep_gate_start, load_datnum, hqpc_bias, ramprate, num, correction_gate, corr_step_ratio, step_gate_isbd, mid, virtual_gate, natarget])
	// Scan at many positions along a transition, centering on transition for each scan along the way. 
	// Rather than doing a true scan along transition, this just takes a series of short repeat measurements in small steps. Will make LOTS of dats, but keeps things a lot simpler
	// step_gate: Gate to step along transition with. These always do fixed steps, center_gate is used to center back on transition
	// step_size: mV to step between each repeat scan
	// step_range: How far to keep stepping in step_gate (i.e. 50 would mean 10 steps for 5mV step size)
	// center_gate: Gate to use for centering on transition
	// sweep_gate: Gate to sweep for scan (i.e. plunger or accumulation)
	// center_step_ratio: Roughly the amount center_gate needs to step to counteract step_gates (will default to 0)
	// centering_width: How wide to scan for CenterOnTransition
	// center_sweep_gate: Whether to also center the sweep gate, or just sweep around 0
	// width: Width of scan around center of transition in sweep_gate (actually sweeps + and - width)
	// correct_cs_gate: Gate to use for correcting the Charge Sensor
	// sweep_gate_start: Start point for sweepgate, useful when loading from hdf
	// correction_gate: Secondary stepping gate for something like a constant gamma scan
	// corr_step_ratio: Proportion of step gate potential to apply to the correction gate each step
	// step_gate_isbd: If step gate is on bd, set = 1
	// natarget: Target mV for current amp
	variable step_size, step_range, center_step_ratio, sweeprate, repeats, center_sweep_gate, width, sweep_gate_start, load_datnum, centering_width, hqpc_bias, ramprate, num, corr_step_ratio, step_gate_isbd, mid, virtual_gate, natarget
	string step_gate, center_gate, sweep_gate, correct_cs_gate, scan_type, correction_gate

	center_step_ratio = paramisdefault(center_step_ratio) ? 0 : center_step_ratio
	corr_step_ratio = paramisdefault(corr_step_ratio) ? 0 : corr_step_ratio
	hqpc_bias = paramisdefault(hqpc_bias) ? 0 : hqpc_bias
	centering_width = paramIsDefault(centering_width) ? 50 : centering_width
	scan_type = selectstring(paramIsDefault(scan_type), scan_type, "transition")
	correct_cs_gate = selectstring(paramIsDefault(correct_cs_gate), correct_cs_gate, "CSQ")
	ramprate = paramisDefault(ramprate) ? 5*sweeprate : ramprate
	num =  paramisDefault(num) ? 1 : num
	step_gate_isbd =  paramisDefault(step_gate_isbd) ? 0 : step_gate_isbd
	variable step_gate_isfd = !step_gate_isbd
	mid =  paramisDefault(mid) ? 0 : mid
	natarget = paramisdefault(natarget) ? 6.3 : natarget //7 
	
	nvar fd, bd

	if (!paramIsDefault(load_datnum))
		loadFromHDF(load_datnum, no_check=1)
		if (!paramisdefault(sweep_gate_start))
			rampmultiplefdac(fd, sweep_gate, sweep_gate_start)
		endif
	endif


	wave/T fdacvalstr
	wave/T dacvalstr

	variable sg_val, cg_val, corrg_val, csq_val
	variable total_scan_range = 0  // To keep track of how far has been scanned
	variable i = 0
	variable center_limit = 100  // Above this value in step gate, don't try to center (i.e. gamma broadened)
	
	do 
		if (step_gate_isfd)
			sg_val = str2num(fdacvalstr[str2num(SF_get_channels(step_gate, fastdac=1))][1]) //get DAC val of step_gates
		else 
			sg_val = str2num(dacvalstr[str2num(SF_get_channels(step_gate, fastdac=0))][1]) //get DAC val of step_gates
		endif
		if (cmpstr(center_gate, sweep_gate) == 0)
			cg_val = mid
		else
			cg_val = str2num(fdacvalstr[str2num(SF_get_channels(center_gate, fastdac=1))][1]) //get DAC val of centering_gate
		endif
		if (!paramIsDefault(correction_gate))
			corrg_val = str2num(fdacvalstr[str2num(SF_get_channels(correction_gate, fastdac=1))][1]) //get DAC val of correction_gate
		endif
		
		RampMultiplefdac(fd, sweep_gate, mid) 
		
		if (i != 0)
			if (step_gate_isfd)
				RampMultiplefdac(fd, step_gate, sg_val+step_size)
			else
				RampMultiplebd(bd, step_gate, sg_val+step_size)
			endif
			RampMultiplefdac(fd, center_gate, cg_val+step_size*center_step_ratio)
			total_scan_range += step_size
			if (!paramIsDefault(correction_gate))
				RampMultiplefdac(fd, correction_gate, corrg_val+step_size*corr_step_ratio)
			endif
			sg_val = sg_val+step_size
		endif
		
		RampMultiplefdac(fd, sweep_gate, mid-50) 
		CorrectChargeSensor(fd=fd, fdchannelstr=correct_cs_gate, fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=natarget)  
		RampMultiplefdac(fd, sweep_gate, mid) 
////////////////////////////////////////////////////////////// THIS SHOULD USUALLY BE ON ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		if(sg_val < center_limit)
			cg_val = CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
			RampMultiplefdac(fd, sweep_gate, mid-200)
			CorrectChargeSensor(fd=fd, fdchannelstr=correct_cs_gate, fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=natarget)  
			RampMultiplefdac(fd, sweep_gate, mid)
			cg_val = CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
		endif
//////////////////////////////////////////////////////////// THIS SHOULD USUALLY BE ON ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		if (cmpstr(center_gate, sweep_gate) == 0)  // If center gate is also sweep gate, then need to get new mid cg_val
			mid = cg_val
		endif
		if (center_sweep_gate)
			mid = CenterOnTransition(gate=sweep_gate, width=width, single_only=1)
		else
			mid = mid
		endif

		RampMultiplefdac(fd, sweep_gate, mid-200)
		CorrectChargeSensor(fd=fd, fdchannelstr=correct_cs_gate, fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=natarget)  
//		
//		// Do CSQ trace to find most sensitive/linear region of CS
//		natarget = GetTargetCSCurrent()
//		
//		RampMultiplefdac(fd, sweep_gate, mid)  
		
		//Center again ... GetTargetCSCurrent changes things (sometimes) by a lot
//		if(sg_val < center_limit)
////			CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
//			RampMultiplefdac(fd, sweep_gate, mid-200)    
//			CorrectChargeSensor(fd=fd, fdchannelstr=correct_cs_gate, fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=natarget)  
//			RampMultiplefdac(fd, sweep_gate, mid)
//		endif
		string virtual_mids
		strswitch (scan_type)
			case "center_test":
				ScanFastDAC(fd, -5000, 5000, "ACC*1000", sweeprate=10000, nosave=1)
				rampmultiplefdac(fd, "ACC*1000", 0)	
				break
			case "transition":
				virtual_mids = num2str(sg_val)
				ScanTransition(sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=center_sweep_gate, mid=mid, virtual_gate=virtual_gate, virtual_mids=virtual_mids)
//				ScanFastDAC(fd, -1000, 1000, "ACC*1000", sweeprate=250, nosave=1)
//				rampmultiplefdac(fd, "ACC*1000", 0)
				break
			case "impurity_transition":
				ScanTransition(sweep_gate="IP1*200", sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=center_sweep_gate, mid=mid)
//				ScanFastDAC(fd, -500, 500, "IP1*200", sweeprate=1000, nosave=1)
//				rampmultiplefdac(fd, "IP1*200", 0)	
				break
			case "entropy":
				virtual_mids = num2str(sg_val)
//				ScanEntropyRepeat(center_first=0, balance_multiplier=1, width=width, hqpc_bias=hqpc_bias, additional_comments=", scan along transition, scan:"+num2str(i), sweeprate=sweeprate, two_part=0, repeats=repeats, num=num, center=mid, virtual_gate=virtual_gate, virtual_mids=virtual_mids)
				ScanEntropyRepeat(center_first=0, balance_multiplier=1, width=width, hqpc_bias=hqpc_bias, additional_comments=", scan along transition, scan:"+num2str(i), sweeprate=sweeprate, two_part=0, repeats=repeats, num=num, center=mid, virtual_gate=virtual_gate, virtual_mids=virtual_mids, freq=12.5, cycles=1)
				rampmultiplefdac(fd, step_gate, sg_val)
//				ScanFastDAC(fd, -5000, 5000, "ACC*1000", sweeprate=10000, nosave=1)
//				rampmultiplefdac(fd, "ACC*1000", 0)	
				break
			case "entropy+transition":
				ScanEntropyRepeat(center_first=0, balance_multiplier=1, width=width, hqpc_bias=hqpc_bias, additional_comments=", scan along transition, scan:"+num2str(i), sweeprate=sweeprate, two_part=0, repeats=repeats, num=num, center=mid)
				ScanTransition(sweeprate=sweeprate*50, width=width*1.5, ramprate=30000, repeats=repeats*5, center_first=0, additional_comments=", scan along transition, scan:"+num2str(i), mid=mid)				
//				ScanFastDAC(fd, mid-5000, mid+5000, "ACC*1000", sweeprate=50000, ramprate=100000, nosave=1)
//				rampmultiplefdac(fd, "ACC*1000", mid)				
				break
			case "csq only":
				RampMultiplefdac(fd, "ACC*1000", -10000)
				csq_val = str2num(fdacvalstr[str2num(SF_get_channels("CSQ", fastdac=1))][1])
				ScanFastDAC(fd, csq_val-50, csq_val+50, "CSQ", sweeprate=100, nosave=0, comments="charge sensor trace")
				RampMultiplefdac(fd, "ACC*1000", 0)
				RampMultiplefdac(fd, "CSQ", csq_val)
				break
			case "backaction noise":
				DotTuneAround(0, 0, 5000, 500, "ACC*1000", "IP1*200", sweeprate=40000, ramprate_x=200000, numptsy=31)
				break
			case "lever_arm":
				ScanFastDAC2D(fd, mid-width, mid+width, sweep_gate, -100, 100, "DO*100", repeats, sweeprate=sweeprate, rampratex=sweeprate*10, comments="lever arm, Reservoir potential vs Sweep gate")
				rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
				rampmultiplefdac(fd, "DO*100", 0)
				break
			case "acc_lever_arm":
				cg_val = str2num(fdacvalstr[str2num(SF_get_channels(center_gate, fastdac=1))][1])
			
				rampmultiplefdac(fd, "ACC*1000", 0)
				rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
				CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
				ScanTransition(sweep_gate=sweep_gate, sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=center_sweep_gate, mid=mid)
				
				rampmultiplefdac(fd, "ACC*1000", -10000)
				rampmultiplefdac(fd, center_gate, cg_val+120)
				rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
				CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
				ScanTransition(sweep_gate=sweep_gate, sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=center_sweep_gate, mid=mid)
				
				rampmultiplefdac(fd, "ACC*1000", 10000)
				rampmultiplefdac(fd, center_gate, cg_val-120)
				rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
				CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
				ScanTransition(sweep_gate=sweep_gate, sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=center_sweep_gate, mid=mid)
				
				rampmultiplefdac(fd, "ACC*1000", 0)
				rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
				rampmultiplefdac(fd, center_gate, cg_val)

				break
			default:
				abort scan_type + " not recognized"
		endswitch
		i++
		
	while (total_scan_range + step_size <= step_range)
	
end
