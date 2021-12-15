////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////// Noise Measurements /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function standardNoiseMeasurement([instrID, comments, nosave])
	// Run standard noise measurement (i.e. 5x 12s scans with fastdac reading 12kHz)
	// ca_amp_setting = amplification on current amp (i.e. for 1e8 enter 8)
	variable instrID, nosave
	string comments

	if(paramIsDefault(instrID))
		nvar fd
		instrID = fd
	endif
	comments = selectString(paramIsDefault(comments), comments, "")

	variable current_freq = getFADCspeed(instrID)
	setFADCSpeed(instrID, 12195)
	FDSpectrumAnalyzer(instrID,12,numAverage=5,comments="noise, spectrum, "+comments, nosave=nosave)
	setFADCSpeed(instrID, current_freq)
end


function QpcStabilitySweeps()
	// 30 mins of slow sweeping down to pinch off and back to depletion to check QPC is stable (taking 90s per sweep, 10 back and forth sweeps)
	nvar fd
	variable pinchoff = -450
	variable depletion = -50

	ScanfastDAC(fd, depletion, pinchoff, "CSQ,CSS", numptsy=20, sweeprate=abs(depletion-pinchoff)/90, alternate=1, comments="repeat, alternating, checking stability of CS gates", nosave=0)
	rampmultipleFDAC(fd, "CSQ,CSS", 0)
end



function NoiseOnOffTranisiton()

	nvar fd
	variable mid
	ScanFastDAC(fd, -150, -210, "CSQ", sweeprate=20, comments="QPC trace before On/Off transition", nosave=0)
	
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, natarget=2.1,  check=0, direction=1)	
	
	CenterOnTransition(gate="ACC*400", width=500, single_only=1)	
	ScanFastDAC(fd, -600, -600, "ACC*400", sweeprate=100, comments="Charge transition before On/Off transition", nosave=0)
	variable i
	for (i=0; i<30; i++)
		mid = CenterOnTransition(gate="ACC*400", width=500, single_only=1)
		printf "Center of transition at ACC*400 = %.2f\r", mid
		asleep(3)
		FDSpectrumAnalyzer(fd,30,numAverage=1,comments="noise, spectrum, On Transition")
		rampmultipleFDAC(fd, "ACC*400", mid-500)

		asleep(3)
		FDSpectrumAnalyzer(fd,30,numAverage=1,comments="noise, spectrum, Off Transition")
		rampmultipleFDAC(fd, "ACC*400", mid)
	endfor
	
	CenterOnTransition(gate="ACC*400", width=500, single_only=1)	
	ScanFastDAC(fd, -600, -600, "ACC*400", sweeprate=100, comments="Charge transition after On/Off transition", nosave=0)
	
	ScanFastDAC(fd, -100, -180, "CSQ", sweeprate=20, comments="QPC trace after On/Off transition", nosave=0)
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, natarget=2.1,  check=0, direction=1)	
end




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////// Dot Tuning Stuff /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

function PinchTestBD(bd, start, fin, channels, numpts, delay, ramprate, current_wave, cutoff_nA, gates_str)
	/// For testing pinch off (10/2/2020)
	// Make sure current wave is in nA
	variable bd, start, fin, numpts, delay, ramprate, cutoff_nA
	string channels, current_wave, gates_str
	rampmultiplebd(bd, channels, 0, ramprate=ramprate)
	string comment
	sprintf comment, "pinch, gates=(%s)", gates_str
	abort "needs reimplmenting"
//	ScanBabyDACUntil(bd, start, fin, channels, numpts, delay, ramprate, current_wave, cutoff_nA, operator="<", comments=comment)
	rampmultiplebd(bd, channels, 0, ramprate=ramprate)
end

function DotTuneAround(x, y, width_x, width_y, channelx, channely, [sweeprate, ramprate_x, numptsy, y_is_bd, csname, nosave, additional_comments])
// Goes to x, y. Sets charge sensor to target_current. Scans2D around x, y +- width.
	variable x, y, width_x, width_y, ramprate_x, nosave, y_is_bd
	variable sweeprate, numptsy
	string channelx, channely, csname, additional_comments

	variable natarget = 2.2   // ADC reading in mV to get most sensitive part of CS
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
	displaydiff(tempwave, filenum=filenum-1, x_label=scu_getDacLabel(scu_getChannelNumbers(channelx, fastdac=1), fastdac=1), y_label=scu_getDacLabel(scu_getChannelNumbers(channely, fastdac=1), fastdac=1))
end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////// Generally Useful Scan Functions ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function ScanAlongTransition(step_gate, step_size, step_range, center_gate, sweep_gate, sweeprate, repeats, width, [center_step_ratio, centering_width, center_sweep_gate, scan_type, correct_cs_gate, sweep_gate_start, load_datnum, hqpc_bias, ramprate, num, correction_gate, corr_step_ratio, step_gate_isbd, mid, virtual_gate, natarget, additional_Setup])
	// Scan at many positions along a transition, centering on transition for each scan along the way.
	// Rather than doing a true scan along transition, this just takes a series of short repeat measurements in small steps. Will make LOTS of dats, but keeps things a lot simpler
	//
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
	// hqpc_bias: mV to apply to current bias resistor for square entropy heating
	// num: Number of times to repeat measurement at each step
	// correction_gate: Secondary stepping gate for something like a constant gamma scan
	// corr_step_ratio: Proportion of step gate potential to apply to the correction gate each step
	// step_gate_isbd: If step gate is on bd, set = 1
	// mid: center value for sweepgate
	// natarget: Target nA for current amp
	// additional_setup: set to 1 to call additionalSetupAfterLoadHDF()  (i.e. useful if LoadfromHDF gets almost all the gates right, and then there a few minor tweaks after that).
	variable step_size, step_range, center_step_ratio, sweeprate, repeats, center_sweep_gate, width, sweep_gate_start, load_datnum, centering_width, hqpc_bias, ramprate, num, corr_step_ratio, step_gate_isbd, mid, virtual_gate, natarget, additional_setup
	string step_gate, center_gate, sweep_gate, correct_cs_gate, scan_type, correction_gate

	center_step_ratio = paramisdefault(center_step_ratio) ? 0 : center_step_ratio
	corr_step_ratio = paramisdefault(corr_step_ratio) ? 0 : corr_step_ratio
	hqpc_bias = paramisdefault(hqpc_bias) ? 25 : hqpc_bias
	centering_width = paramIsDefault(centering_width) ? 20 : centering_width
	scan_type = selectstring(paramIsDefault(scan_type), scan_type, "transition")
	correct_cs_gate = selectstring(paramIsDefault(correct_cs_gate), correct_cs_gate, "CSQ")
	ramprate = paramisDefault(ramprate) ? 10*sweeprate : ramprate
	num =  paramisDefault(num) ? 1 : num
	step_gate_isbd =  paramisDefault(step_gate_isbd) ? 0 : step_gate_isbd
	variable step_gate_isfd = !step_gate_isbd
	mid =  paramisDefault(mid) ? 0 : mid
	natarget = paramisdefault(natarget) ? 2.1 : natarget //2.1 at 100uV, 0.4nA at 15uV
	variable center_limit = -120  // Above this value in step gate, don't try to center (i.e. gamma broadened)


	nvar fd, bd

	if (!paramIsDefault(load_datnum))
		loadFromHDF(load_datnum, no_check=1)
		if (additional_setup)
			additionalSetupAfterLoadHDF()
		endif
		if (!paramisdefault(sweep_gate_start))
			rampmultiplefdac(fd, sweep_gate, sweep_gate_start)
		endif
	endif

	wave/T fdacvalstr
	wave/T dacvalstr

	variable sg_val, cg_val, corrg_val, csq_val
	variable total_scan_range = 0  // To keep track of how far has been scanned
	variable i = 0

	do
		// Get DAC val of step_gate
		if (step_gate_isfd)
			sg_val = str2num(fdacvalstr[str2num(scu_getChannelNumbers(step_gate, fastdac=1))][1])
		else
			sg_val = str2num(dacvalstr[str2num(scu_getChannelNumbers(step_gate, fastdac=0))][1])
		endif
		
		// Get DAC val of centering_gate
		if (cmpstr(center_gate, sweep_gate) == 0)
			cg_val = mid
		else
			cg_val = str2num(fdacvalstr[str2num(scu_getChannelNumbers(center_gate, fastdac=1))][1]) //get DAC val of centering_gate
		endif
		
		// Get DAC val of correction_gate
		if (!paramIsDefault(correction_gate))
			corrg_val = str2num(fdacvalstr[str2num(scu_getChannelNumbers(correction_gate, fastdac=1))][1]) //get DAC val of correction_gate
		endif

		// Reset sweepgate
		RampMultiplefdac(fd, sweep_gate, mid)

		// Ramp step_gate (and correction_gate) to next value
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
		
		// Center and correct charge sensor
		RampMultiplefdac(fd, sweep_gate, mid-50)
		CorrectChargeSensor(fd=fd, fdchannelstr=correct_cs_gate, fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=natarget)
		RampMultiplefdac(fd, sweep_gate, mid)
		if(sg_val < center_limit)
			cg_val = CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
			RampMultiplefdac(fd, sweep_gate, mid-200)
			CorrectChargeSensor(fd=fd, fdchannelstr=correct_cs_gate, fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=natarget)
			RampMultiplefdac(fd, sweep_gate, mid)
			cg_val = CenterOnTransition(gate=center_gate, width=centering_width, single_only=1)
		endif
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


		string virtual_mids
		strswitch (scan_type)
			case "center_test":
				ScanFastDAC(fd, -1000, 1000, "ACC*400", sweeprate=10000, nosave=1)
				rampmultiplefdac(fd, "ACC*400", 0)
				break
			case "transition":
				virtual_mids = num2str(sg_val)
				ScanTransition(sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=center_sweep_gate, mid=mid, virtual_gate=virtual_gate, virtual_mids=virtual_mids)
				break
			case "dcbias_transition":
				virtual_mids = num2str(sg_val)
				rampmultipleFDAC(fd, "OHC(10M)", hqpc_bias)
				rampmultipleFDAC(fd, "OHV*1000", hqpc_bias*-1.503)
				ScanTransition(sweeprate=sweeprate, width=width, ramprate=ramprate, repeats=repeats, center_first=center_sweep_gate, mid=mid, virtual_gate=virtual_gate, virtual_mids=virtual_mids, additional_comments="dcbias="+num2str(hqpc_bias))
				break
			case "entropy":
				virtual_mids = num2str(sg_val)
				ScanEntropyRepeat(center_first=0, balance_multiplier=1, width=width, hqpc_bias=hqpc_bias, additional_comments=", scan along transition, scan:"+num2str(i), sweeprate=sweeprate, two_part=0, repeats=repeats, num=num, center=mid, virtual_gate=virtual_gate, virtual_mids=virtual_mids)
				break
			case "entropy+transition":
				ScanEntropyRepeat(center_first=0, balance_multiplier=1, width=width, hqpc_bias=hqpc_bias, additional_comments=", scan along transition, scan:"+num2str(i), sweeprate=sweeprate, two_part=0, repeats=repeats, num=num, center=mid)
				ScanTransition(sweeprate=sweeprate*50, width=width*1.5, ramprate=30000, repeats=repeats*5, center_first=0, additional_comments=", scan along transition, scan:"+num2str(i), mid=mid)
				break
			case "csq only":
				RampMultiplefdac(fd, "ACC*1000", -10000)
				csq_val = str2num(fdacvalstr[str2num(scu_getChannelNumbers("CSQ", fastdac=1))][1])
				ScanFastDAC(fd, csq_val-50, csq_val+50, "CSQ", sweeprate=100, nosave=0, comments="charge sensor trace")
				RampMultiplefdac(fd, "ACC*1000", 0)
				RampMultiplefdac(fd, "CSQ", csq_val)
				break
			default:
				abort scan_type + " not recognized"
		endswitch
		i++

	while (total_scan_range + step_size <= step_range)

end



function TimStepTempScanSomething()
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


function ScanEntropyRepeat([num, center_first, balance_multiplier, width, hqpc_bias, additional_comments, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center, virtual_gate, virtual_mids, cycles])
	variable num, center_first, balance_multiplier, width, hqpc_bias, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center, virtual_gate, cycles
	string additional_comments, virtual_mids
	nvar fd

	num = paramisdefault(num) ? 										INF : num
	center_first = paramisdefault(center_first) ? 				0 : center_first
	balance_multiplier = paramisdefault(balance_multiplier) ? 	1 : balance_multiplier
	hqpc_bias = paramisdefault(hqpc_bias) ? 						25 : hqpc_bias
	repeat_multiplier = paramisDefault(repeat_multiplier) ? 	1 : repeat_multiplier
	sweeprate = paramisdefault(sweeprate) ? 						100 : sweeprate
	freq = paramisdefault(freq) ? 									12.5 : freq
	two_part = paramisdefault(two_part) ? 							0 : two_part
	center = paramisdefault(center) ? 								0 : center
	cycles = paramisdefault(cycles) ? 								1 : cycles

	string virtual_gates = "IP1*200"
	string ratios = "-0.0914"

	string sweepgate = "ACC*400"
	variable sweepgate_center_width = 500
	string centergate = "ACC*2"
	variable center_width = 30

	nvar sc_ResampleFreqCheckfadc
	sc_ResampleFreqCheckfadc = 0  // Resampling in entropy measurements screws things up at the moment so turn it off (2021-12-02)

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
		rampmultiplefdac(fd, sweepgate, center)
		centerontransition(gate=centergate, width=center_width)
		rampmultiplefdac(fd, sweepgate, center-200)
		if (!paramisdefault(cs_target))
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=cs_target)
		else
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)
		endif
		rampmultiplefdac(fd, sweepgate, center)
		mid = centerontransition(gate=sweepgate, width=sweepgate_center_width, single_only=1)
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
			printf "Starting scan %d of \u221E\r", i+1
		else
			printf "Starting scan %d of %d\r", i+1, num
		endif
		if (two_part == 1)
			ScanFastDAC(fd, mid-width1, mid+width1, sweepgate, numptsy=repeats1, sweeprate=sweeprate, delay=0.2, comments=comments+", part1of2", use_awg=1, nosave=nosave)
			ScanFastDAC(fd, mid-width2, mid+width2, sweepgate, numptsy=repeats2, sweeprate=sweeprate, delay=0.2, comments=comments+", part2of2", use_awg=1, nosave=nosave)
		else
			if (!paramisDefault(repeats) && repeats > 0)
				r = repeats
			else
				r = repeats2
			endif
			if (virtual_gate)
				virtual_starts_ends = get_virtual_scan_params(mid, width1, virtual_mids, ratios)
				ScanFastDAC(fd, 0, 0, addlistItem(virtual_gates, sweepgate, ",", INF), numptsy=r, starts=stringfromlist(0, virtual_starts_ends), fins=stringfromlist(1, virtual_starts_ends), sweeprate=sweeprate, delay=0.1, comments=comments, use_awg=1, nosave=nosave)
			else
				ScanFastDAC(fd, mid-width1, mid+width1, sweepgate, numptsy=r, sweeprate=sweeprate, delay=0.1, comments=comments, use_awg=1, nosave=nosave)
			endif
		endif
		rampmultiplefdac(fd, sweepgate, mid)
		i++
	while (i<num)
end



function ScanTransition([sweeprate, width, ramprate, repeats, center_first, center_gate, center_width, sweep_gate, additional_comments, mid, cs_target, virtual_gate, virtual_mids, csqpc_gate])
	variable sweeprate, width, ramprate, repeats, center_first, center_width, mid, cs_target, virtual_gate
	string center_gate, sweep_gate, additional_comments, virtual_mids, csqpc_gate
	nvar fd

	string virtual_gates = "IP1*200"
	string ratios = "-0.0914"

	sweeprate = paramisdefault(sweeprate) ? 100 : sweeprate
	width = paramisdefault(width) ? 2000 : width
	ramprate = paramisDefault(ramprate) ? 10000 : ramprate
	repeats = paramIsDefault(repeats) ? 10 : repeats

	// let center_first default to 0
	sweep_gate = selectstring(paramisdefault(sweep_gate), sweep_gate, "ACC*400")
	center_gate = selectstring(paramisdefault(center_gate), center_gate, "ACC*2")
	center_width = paramisDefault(center_width) ? 20 : center_width
	additional_comments = selectstring(paramisdefault(additional_comments), additional_comments, "")
	csqpc_gate = selectstring(paramisdefault(csqpc_gate), csqpc_gate, "CSQ")

	if (center_first)
		variable center_gate_mid
		rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
		center_gate_mid = centerontransition(gate=center_gate, width=center_width, single_only=1)
		mid = (cmpstr(center_gate, sweep_gate) == 0) ? center_gate_mid : mid  // If centering with sweepgate, update the mid value
		printf "Centered at %s=%.2f mV\r" center_gate, center_gate_mid
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
		ScanFastDAC(fd, 0, 0, addlistItem(virtual_gates, sweep_gate, ",", INF), numptsy=repeats, starts=stringfromlist(0, virtual_starts_ends), fins=stringfromlist(1, virtual_starts_ends), sweeprate=sweeprate, ramprate=ramprate, delay=0.01, comments="transition, repeat" + additional_comments, nosave=0)
	else
		ScanFastDAC(fd, mid-width, mid+width, sweep_gate, numptsy=repeats, sweeprate=sweeprate, ramprate=ramprate, delay=0.01, comments="transition, repeat" + additional_comments, nosave=0)
	endif
	rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
end



function ScanTransitionMany()
	nvar fd

	make/o/free Var1  = {-440, 	-410,	-400,	-385,	-356,	-331,	-307,	-281,	-257,	-231,	-205}  // ACC*2
	make/o/free Var1b = {-25, 	-100,	-150,	-200,	-300,	-400,	-500,	-600,	-700,	-800,	-900}  // SDP
	make/o/free Var2 = {0}
	make/o/free Var3 = {0}

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
				printf "Starting scan at i=%d, SDP = %.1fmV \r", i, Var1b[i]
				rampmultiplefdac(fd, "ACC*2", Var1[i])
				rampmultiplefdac(fd, "SDP", Var1b[i])
				for(repeats=0;repeats<1;repeats++)
//					ScanEntropyRepeat(num=1, center_first=1, balance_multiplier=1, width=200, hqpc_bias=25, additional_comments="0->1 transition", repeat_multiplier=1, freq=12.5, sweeprate=25, two_part=0, repeats=5, center=0)
					ScanTransition(sweeprate=25, width=400, repeats=2, center_first=1, center_gate="ACC*2", center_width=20, sweep_gate="ACC*400", additional_comments="rough check before entropy scans", csqpc_gate="CSQ")
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
	ScanFastDAC(fd, -scan_width, scan_width, "ACC*400", numptsy=repeats, ramprate=rampratex, sweeprate=sweeprate, comments=comments, nosave=0)

	// Measure with non-zero bias
	variable setpoint
	variable i
	for (i=1; i<num_steps+1; i++)  // Start from 1 for only non-zero bias
		setpoint = i*(max_current*10/num_steps)

		// Measure positive bias
		rampmultipleFDAC(fd, current_channel, setpoint)
		rampmultipleFDAC(fd, voltage_channel, -setpoint*voltage_ratio)
		sprintf comments, "DCbias Repeat, %.3f nA" setpoint/current_resistor
		ScanFastDAC(fd, -scan_width, scan_width, "ACC*400", numptsy=repeats, ramprate=rampratex, sweeprate=sweeprate, comments=comments, nosave=0)

		// Measure negative bias
		rampmultipleFDAC(fd, current_channel, -setpoint)
		rampmultipleFDAC(fd, voltage_channel, setpoint*voltage_ratio)
		sprintf comments, "DCbias Repeat, %.3f nA" -setpoint/current_resistor
		ScanFastDAC(fd, -scan_width, scan_width, "ACC*400", numptsy=repeats, ramprate=rampratex, sweeprate=sweeprate, comments=comments, nosave=0)

	endfor

	// Return to zero heating
	rampmultipleFDAC(fd, current_channel, 0)
	rampmultipleFDAC(fd, voltage_channel, 0)
end



