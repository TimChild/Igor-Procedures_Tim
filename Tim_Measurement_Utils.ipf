//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////// Measurement Utilities   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////
////////////////////////////// FD/AWG ///////////////////////////////////
/////////////////////////////////////////////////////////////////////////

function SetupEntropySquareWaves([freq, cycles, hqpc_plus, hqpc_minus, channel_ratio, balance_multiplier, hqpc_bias_multiplier, ramplen])
	variable freq, cycles, hqpc_plus, hqpc_minus, channel_ratio, balance_multiplier, hqpc_bias_multiplier, ramplen

	balance_multiplier = paramIsDefault(balance_multiplier) ? 1 : balance_multiplier
	hqpc_bias_multiplier = paramIsDefault(hqpc_bias_multiplier) ? 1 : hqpc_bias_multiplier
	freq = paramisdefault(freq) ? 12.5 : freq
	cycles = paramisdefault(cycles) ? 1 : cycles
	hqpc_plus = paramisdefault(hqpc_plus) ? 50 : hqpc_plus
	hqpc_minus = paramisdefault(hqpc_minus) ? -50 : hqpc_minus
	channel_ratio = paramisdefault(channel_ratio) ? -1.503 : channel_ratio  //Using OHC, OHV
	ramplen = paramisdefault(ramplen) ? 0 : ramplen

	nvar fd

	variable splus = hqpc_plus*hqpc_bias_multiplier, sminus=hqpc_minus*hqpc_bias_multiplier
	variable cplus=splus*channel_ratio * balance_multiplier, cminus=sminus*channel_ratio * balance_multiplier

	variable spt
	// Make square wave 0
	spt = 1/(4*freq)  // Convert from freq to setpoint time /s  (4 because 4 setpoints per wave)
	fdAWG_make_multi_square_wave(fd, 0, splus, sminus, spt, spt, spt, 0, ramplen=ramplen)
	// Make square wave 1
	fdAWG_make_multi_square_wave(fd, 0, cplus, cminus, spt, spt, spt, 1, ramplen=ramplen)

	// Setup AWG
//	fdAWG_setup_AWG(fd, AWs="0,1", DACs="R2T/0.001,TC/0.001", numCycles=cycles)
//	fdAWG_setup_AWG(fd, AWs="0,1", DACs="HO1/10M,HO2/1000", numCycles=cycles)
	fdAWG_setup_AWG(fd, AWs="0,1", DACs="OHC(10M),OHV*1000", numCycles=cycles)
end


function SetupEntropySquareWaves_unequal([freq, cycles, hqpc_plus, hqpc_minus, ratio_plus, ratio_minus, balance_multiplier, hqpc_bias_multiplier, ramplen])
	variable freq, cycles, hqpc_plus, hqpc_minus, ratio_plus, ratio_minus, balance_multiplier, hqpc_bias_multiplier, ramplen

	balance_multiplier = paramIsDefault(balance_multiplier) ? 1 : balance_multiplier
	hqpc_bias_multiplier = paramIsDefault(hqpc_bias_multiplier) ? 1 : hqpc_bias_multiplier
	freq = paramisdefault(freq) ? 12.5 : freq
	cycles = paramisdefault(cycles) ? 1 : cycles
	hqpc_plus = paramisdefault(hqpc_plus) ? 50 : hqpc_plus
	hqpc_minus = paramisdefault(hqpc_minus) ? -50 : hqpc_minus
	ratio_plus = paramisdefault(ratio_plus) ? -1.531 : ratio_plus
	ratio_minus = paramisdefault(ratio_minus) ? -1.531 : ratio_minus
	ramplen = paramisdefault(ramplen) ? 0 : ramplen

	nvar fd

	variable splus = hqpc_plus*hqpc_bias_multiplier, sminus=hqpc_minus*hqpc_bias_multiplier
	variable cplus=splus*ratio_plus * balance_multiplier, cminus=sminus*ratio_minus * balance_multiplier

	variable spt
	// Make square wave 0
	spt = 1/(4*freq)  // Convert from freq to setpoint time /s  (4 because 4 setpoints per wave)
	fdAWG_make_multi_square_wave(fd, 0, splus, sminus, spt, spt, spt, 0, ramplen=ramplen)
	// Make square wave 1
	fdAWG_make_multi_square_wave(fd, 0, cplus, cminus, spt, spt, spt, 1, ramplen=ramplen)

	// Setup AWG
	fdAWG_setup_AWG(fd, AWs="0,1", DACs="HO1/10M,HO2*1000", numCycles=cycles)
end



function Set_multi_square_wave(instrID, v0, vP, vM, v0len, vPlen, vMlen, wave_num)
   // Wrapper around fdAWG_add_wave to make square waves with form v0, +vP, v0, -vM (useful for Tim's Entropy)
   // To make simple square wave set length of unwanted setpoints to zero.
   variable instrID, v0, vP, vM, v0len, vPlen, vMlen, wave_num  // lens in seconds

   // TODO: need to make a warning that if changing ADC frequency that AWG_frequency changes

   // put into wave to make it easier to work with
   make/o/free sps = {v0, vP, vM}
   make/o/free lens = {v0len, vPlen, vMlen}

   // Sanity check on period
   // Note: limit checks happen in AWG_RAMP  // TODO: put that check in
   if (sum(lens) > 1)
      string msg
      sprintf msg "Do you really want to make a square wave with period %.3gs?", sum(lens)
      variable ans = ask_user(msg, type=1)
      if (ans == 2)
         abort "User aborted"
      endif
   endif

   // make wave to store setpoints/sample_lengths
   make/o/free/n=(-1, 2) awg_sqw  // TODO: check dims of wave

   variable samplingFreq = getFADCspeed(instrID)  // Gets sampling rate of FD (Note: NOT measureFreq here)
   variable numSamples = 0

   variable i=0, j=0
   for(i=0;i<numpnts(sps);i++)
      if(lens[i] != 0)  // Only add to wave if duration is non-zero
         numSamples = round(lens[i]*samplingFreq)  // Convert to # samples
         if(numSamples == 0)  // Prevent adding zero length setpoint
            abort "ERROR[Set_multi_square_wave]: trying to add setpoint with zero length, duration too short for sampleFreq"
         endif
         awg_sqw[j] = {sps[i], numSamples}
         j++
      endif
   endfor

   if(numpnts(awg_sqw) == 0)
      abort "ERROR[Set_multi_square_wave]: No setpoints added to awg_sqw"
   endif

   fdAWG_clear_wave(instrID, wave_num)
   fdAWG_add_wave(instrID, wave_num, awg_sqw)
   printf "Set square wave on AWG_wave%d", wave_num
end





//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////




function loadFromHDF(datnum, [no_check])
	variable datnum, no_check

	bdLoadFromHDF(datnum, no_check = no_check)
	fdLoadFromHDF(datnum, no_check = no_check)
end


////////////////////////////// Charge sensor functions ///////////////////////////////////////


function GetTargetCSCurrent([oldcscurr, lower_lim, upper_lim, nosave])
// A rough outline for a new correctchargesensor function. Currently relies on defaults in CorrectChargeSensor
// To be implemented into CorrectChargeSensor after some testing
	variable oldcscurr, lower_lim, upper_lim, nosave
	nvar fd
	string channelstr = "CSQ"

	channelstr = SF_get_channels(channelstr, fastdac=1)

	lower_lim = paramisdefault(lower_lim) ? 4 : lower_lim
	upper_lim = paramisdefault(upper_lim) ? 9 : upper_lim
	nosave = paramisdefault(nosave) ? 1 : nosave

	// Begin by calling CorrectChargeSensor with default things
	if (paramisDefault(oldcscurr))
		CorrectChargeSensor(fd=fd, fdchannelstr=channelstr, fadcID=fd, fadcchannel=0, check=0, direction=1)
		oldcscurr = getFADCvalue(fd, 0, len_avg=0.3)
	else
		CorrectChargeSensor(fd=fd, fdchannelstr=channelstr, fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=oldcscurr)
	endif

	// Get the current value of CSQ
	wave/T fdacvalstr
	variable oldcenter = str2num(fdacvalstr[str2num(channelstr)][1])

	// Sweep CSQ +/- 20 mV around the current setting to get the charge sensor curve
	ScanFastDAC(fd, oldcenter-20, oldcenter+20, channelstr, numpts=10000, nosave=nosave, comments="Finding steepest part of CSQ, CSQ scan")
	wave cscurrent

	duplicate/o/free cscurrent cscurrentdiff
	cscurrentdiff = (lower_lim < cscurrent[p] && cscurrent[p] < upper_lim) ? cscurrent[p] : NaN
	wavestats/Q cscurrentdiff
	resample/DOWN=(floor((V_npnts)/50)) cscurrentdiff
	differentiate cscurrentdiff
	smooth 10, cscurrentdiff

	wavestats/Q cscurrentdiff
	variable newcenter = V_maxloc

	// If Igor gives garbage, go back to the original center and return
	if(newcenter > oldcenter + 30 || newcenter < oldcenter - 30)
		rampmultiplefdac(fd, channelstr, oldcenter)
		printf "WARNING [GetTargetCSCurrent]: Thought center of CS trace was at %.1fmV, centering at %.1fmV\n", newcenter, oldcenter
		return oldcscurr
	endif

	rampmultiplefdac(fd, channelstr, newcenter)
	variable newcscurr = getFADCvalue(fd, 0, len_avg=0.3)

	// If a strangely small or large cscurrent, ramp back to center and return
	if(newcscurr > upper_lim || newcscurr < lower_lim)
		rampmultiplefdac(fd, channelstr, oldcenter)
		printf "WARNING [GetTargetCSCurrent]: Thought natarget was at %.1fmV, using %.1fmV\n", newcscurr, oldcscurr
		return oldcscurr
	endif

	return newcscurr
end

function CorrectChargeSensor([bd, bdchannelstr, dmmid, fd, fdchannelstr, fadcID, fadcchannel, i, check, natarget, direction, zero_tol])
//Corrects the charge sensor by ramping the CSQ in 1mV steps
//(direction changes the direction it tries to correct in)
	variable bd, dmmid, fd, fadcID, fadcchannel, i, check, natarget, direction, zero_tol
	string fdchannelstr, bdchannelstr
	variable cdac, cfdac, current, new_current, nextdac, j
	wave/T dacvalstr
	wave/T fdacvalstr

	natarget = paramisdefault(natarget) ? 1630 : natarget
	direction = paramisdefault(direction) ? 1 : direction
	zero_tol = paramisdefault(zero_tol) ? 0.5 : zero_tol  // How close to zero before it starts to get more averaged measurements

	if ((paramisdefault(bd) && paramisdefault(fd)) || !paramisdefault(bd) && !paramisdefault(fd))
		abort "Must provide either babydac OR fastdac id"
	elseif  ((paramisdefault(dmmid) && paramisdefault(fadcID)) || !paramisdefault(fadcID) && !paramisdefault(dmmid))
		abort "Must provide either dmmid OR fadcchannel"
	elseif ((!paramisdefault(bd) && paramisDefault(bdchannelstr)) || (!paramisdefault(fd) && paramisDefault(fdchannelstr)))
		abort "Must provide the channel to change for the babydac or fastdac"
	elseif (!paramisdefault(fadcid) && paramisdefault(fadcchannel))
		abort "Must provide fdadcID if using fadc to read current"
	elseif (!paramisdefault(fd) && paramisdefault(fdchannelstr))
		abort "Must provide fdchannel if using fd"
	elseif (!paramisdefault(bd) && paramisdefault(bdchannelstr))
		abort "Must provide bdchannel if using bd"
	endif

	if (!paramisdefault(fdchannelstr))
		fdchannelstr = SF_get_channels(fdchannelstr, fastdac=1)
		if(itemsInList(fdchannelstr, ",") != 1)
			abort "ERROR[CorrectChargeSensor]: Only works with 1 fdchannel"
		else
			variable fdchannel = str2num(fdchannelstr)
		endif
	elseif (!paramisdefault(bdchannelstr))
		bdchannelstr = SF_get_channels(bdchannelstr, fastdac=0)
		if(itemsInList(bdchannelstr, ",") != 1)
			abort "ERROR[CorrectChargeSensor]: Only works with 1 bdchannel"
		else
			variable bdchannel = str2num(bdchannelstr)
		endif
	endif

	sc_openinstrconnections(0)

	//get current
	if (!paramisdefault(dmmid))
		abort
//		current = read34401A(dmmid)
	else
		current = getFADCvalue(fadcID, fadcchannel, len_avg=0.5)
	endif

	variable end_condition = (naTarget == 0) ? zero_tol : 0.05*naTarget   // Either 5% or just an absolute zero_tol given

	variable avg_len = 0.001// Starting time to avg, will increase as it gets closer to ideal value
	if (abs(current-natarget) > end_condition/2)  // If more than half the end_condition out
		do
			//get current dac setting
			if (!paramisdefault(bd))
				cdac = str2num(dacvalstr[bdchannel][1])

			else
				cdac = str2num(fdacvalstr[fdchannel][1])
			endif

			if (current < nAtarget)  // Choose next step direction
				nextdac = cdac+0.32*direction  // 0.305... is FastDAC resolution (20000/2^16)
			else
				nextdac = cdac-0.32*direction
			endif

			if (check==0) //no user input
				if (-1100 < nextdac && nextdac < 100) //Prevent it doing something crazy
					if (!paramisdefault(bd))
						rampmultiplebd(bd, num2str(bdchannel), nextdac)
					else
						rampoutputfdac(fd, fdchannel, nextdac)
					endif
				else
					abort "Failed to correct charge sensor to target current"
				endif
			else //ask for user input
				doAlert/T="About to change DAC" 1, "Scan wants to ramp DAC to " + num2str(nextdac) +"mV, is that OK?"
				if (V_flag == 1)
					if (!paramisdefault(bd))
						rampmultiplebd(bd, num2str(bdchannel), nextdac)
					else
						rampoutputfdac(fd, fdchannel, nextdac)
					endif
				else
					abort "Computer tried to do bad thing"
				endif
			endif

			//get current after dac step
			if (!paramisdefault(dmmid))
				abort "Not implemented DMM again"
//				current = read34401A(dmmid)
			else
				current = getFADCvalue(fadcID, fadcchannel, len_avg=avg_len)
			endif

			doupdate  // Update scancontroller window


			if ((abs(current-nAtarget) < end_condition*3) && avg_len < 0.2)  // If close to end, start averaging for at least 0.2
				avg_len = 0.2
			endif
			if (abs(current-nAtarget) < end_condition*3)  // Average longer each time when close
				avg_len = avg_len*1.2
			endif
			if (avg_len > 1)  // Max average length = 1s
				avg_len = 1
			endif
//			print avg_len

		while (abs(current-nAtarget) > end_condition)   // Until reaching end condition

		if (!paramisDefault(i))
			print "Ramped to " + num2str(nextdac) + "mV, at line " + num2str(i)
		endif
	endif
end


////////////////////////////////// Centering Functions ////////////////////

function FindTransitionMid(dat, [threshold]) //Finds mid by differentiating, returns minloc
	wave dat
	variable threshold
	variable MinVal, MinLoc, w, lower, upper
	threshold = paramisDefault(threshold) ? 2 : threshold  //was 3 before 11thMar2020
	wavestats/Q dat //easy way to get num notNaNs
	w = V_npnts/5 //width to smooth by (relative to how many datapoints taken)
	redimension/N=-1 dat
	smooth w, dat	//Smooth dat so differentiate works better
	duplicate/o/R=[w, numpnts(dat)-w] dat dattemp
	differentiate/EP=1 dattemp /D=datdiff
	wavestats/Q datdiff
	MinVal = V_min  		//Will get overwritten by next wavestats otherwise
	MinLoc = V_minLoc 	//
	Findvalue/V=(minVal)/T=(abs(minval/100)) datdiff //find index of min peak
	lower = V_value-w*0.75 //Region to cut from datdiff
	upper = V_value+w*0.75 //same
	if(lower < 1)
		lower = 0 //make sure it doesn't exceed datdiff index range
	endif
	if(upper > numpnts(datdiff)-2)
		upper = numpnts(datdiff)-1 //same
	endif
	datdiff[lower, upper] = NaN //Remove peak
	wavestats/Q datdiff //calc V_adev without peak
	if(abs(MinVal/V_adev)>threshold)
		//print "MinVal/V_adev = " + num2str(abs(MinVal/V_adev)) + ", at " + num2str(minloc) + "mV"
		return MinLoc
	else
		print "MinVal/V_adev = " + num2str(abs(MinVal/V_adev)) + ", at " + num2str(minloc) + "mV"
		return NaN
	endif
end


function CenterOnTransition([gate, virtual_gates, width, single_only])
	string gate, virtual_gates
	variable width, single_only

	nvar fd

	gate = selectstring(paramisdefault(gate), gate, "LP*2")
	width = paramisdefault(width) ? 50 : width

	gate = SF_get_channels(gate, fastdac=1)

	variable initial, mid
	wave/t fdacvalstr
	initial = str2num(fdacvalstr[str2num(gate)][1])

	ScanFastDAC(fd, initial-width, initial+width, gate, sweeprate=width, nosave=1)
	mid = findtransitionmid($"cscurrent", threshold=2)

	if (single_only == 0 && numtype(mid) != 2)
		ScanFastDAC(fd, mid-width/10, mid+width/10, gate, sweeprate=width/10, nosave=1)
		mid = findtransitionmid($"cscurrent", threshold=2)
	endif

	if (abs(mid-initial) < width && numtype(mid) != 2)
		rampmultiplefdac(fd, gate, mid)
	else
		rampmultiplefdac(fd, gate, initial)
		printf "CLOSE CALL: center on transition thought mid was at %dmV\r", mid
		mid = initial
	endif
	return mid
end


function saveLogsOnly([msg])
	string msg
	variable save_experiment // Default: Do not save experiment for just this

	nvar filenum

	if (paramisdefault(msg))
		msg = "SaveLogsOnly"
	endif

	abort "Need to check this works, hopefully it does"

	variable hdfid = initOpenSaveFiles(0)
	LogsOnlySave(hdfid, msg)
//	initSaveFiles(msg=msg, logs_only=1) // Saves logs here, and adds Logs_Only attr to root group of HDF
	initcloseSaveFiles(num2str(hdfid))
end


/////////////////////////////////// Other useful functions //////////////////////////////


function WaitTillTempStable(instrID, targetTmK, times, delay, err)
	// instrID is the lakeshore controller ID
	// targetmK is the target temperature in mK
	// times is the number of readings required to call a temperature stable
	// delay is the time between readings
	// err is a percent error that is acceptable in the readings
	string instrID
	variable targetTmK, times, delay, err
	variable passCount, targetT=targetTmK/1000, currentT = 0

	// check for stable temperature
	print "Target temperature: ", targetTmK, "mK"

	variable j = 0
	for (passCount=0; passCount<times; )
		asleep(delay)
		for (j = 0; j<10; j+=1)
			currentT += getLS370temp(instrID, "mc")/10 // do some averaging
			asleep(2.1)
		endfor
		if (ABS(currentT-targetT) < err*targetT)
			passCount+=1
			print "Accepted", passCount, " @ ", currentT, "K"
		else
			print "Rejected", passCount, " @ ", currentT, "K"
			passCount = 0
		endif
		currentT = 0
	endfor
end
