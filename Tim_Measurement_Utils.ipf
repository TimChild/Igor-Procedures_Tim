//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////// Measurement Utilities   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////
////////////////////////////// FD/AWG ///////////////////////////////////
/////////////////////////////////////////////////////////////////////////

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
	
//	bdLoadFromHDF(datnum, no_check = no_check)
	fdLoadFromHDF(datnum, no_check = no_check)
end


function CorrectChargeSensor([bd, bdchannel, dmmid, fd, fdchannel, fadcID, fadcchannel, i, check, natarget, direction])
//Corrects the charge sensor by ramping the CSQ in 1mV steps (direction changes the direction it tries to correct in)
	variable bd, dmmid, fd, fadcID, fadcchannel, i, check, natarget, bdchannel, fdchannel, direction
	variable cdac, cfdac, current, nextdac
	wave/T dacvalstr
	wave/T fdacvalstr

	natarget = paramisdefault(natarget) ? 0.8 : natarget
	direction = paramisdefault(direction) ? 1 : direction

	if ((paramisdefault(bd) && paramisdefault(fd)) || !paramisdefault(bd) && !paramisdefault(fd))
		abort "Must provide either babydac OR fastdac id"
	elseif  ((paramisdefault(dmmid) && paramisdefault(fadcID)) || !paramisdefault(fadcID) && !paramisdefault(dmmid))
		abort "Must provide either dmmid OR fadcchannel"
	elseif ((!paramisdefault(bd) && paramisDefault(bdchannel)) || (!paramisdefault(fd) && paramisDefault(fdchannel)))
		abort "Must provide the channel to change for the babydac or fastdac"
	elseif (!paramisdefault(fadcid) && paramisdefault(fadcchannel))
		abort "Must provide fdadcID if using fadc to read current"
	elseif (!paramisdefault(fd) && paramisdefault(fdchannel))
		abort "Must provide fdchannel if using fd"
	elseif (!paramisdefault(bd) && paramisdefault(bdchannel))
		abort "Must provide bdchannel if using bd"
	endif

	sc_openinstrconnections(0)

	//get current
	if (!paramisdefault(dmmid))
		current = read34401A(dmmid)
	else
		current = getfadcChannel(fd,fadcchannel)
	endif

	if (abs(current-natarget) > 0.01)
		do

			//get cdac
			if (!paramisdefault(bd))
				cdac = str2num(dacvalstr[bdchannel][1])
			else
				cdac = str2num(fdacvalstr[fdchannel][1])
			endif

			if (current < nAtarget)
				nextdac = cdac+0.3*direction
			else
				nextdac = cdac-0.3*direction
			endif

			if (check==0) //no user input
				if (-800 < nextdac && nextdac < -100) //Prevent it doing something crazy
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
			//get current
			if (!paramisdefault(dmmid))
				current = read34401A(dmmid)
			else
				current = getfadcChannel(fd,fadcchannel)
			endif
		while (abs(current-nAtarget) > 0.005)

		if (!paramisDefault(i))
			print "Ramped to " + num2str(nextdac) + "mV, at line " + num2str(i)
		endif
	endif
end


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
		sc_sleep(delay)
		for (j = 0; j<10; j+=1)
			sc_sleep(1.0)
			currentT += getLS370temp(instrID, "mc")/10 // do some averaging
			sc_sleep(1.0)
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


Function/S GetVKS()  // Safe way to get global variable whether it exists or not
    SVAR/Z zVKS  //Variable Key String
    if(!SVAR_Exists(zVKS))
        string/G zVKS   // zVKS = VariableKeyString (z so at bottom of data folder)
    endif

    return "zVKS"
End


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


function asleep(s)
  // Sleep function which allows user to abort or continue if sleep is longer than 2s
	variable s
	variable t1, t2
	if (s > 2)
		t1 = datetime
		sleep/S/C=6/B/Q s
		t2 = datetime-t1
		if ((s-t2)>5)
			printf "User continued, slept for %.0fs\r", t2
		endif
	else
		sc_sleep(s)
	endif
end


function/S GetLabel(channels, [fastdac])
  // Returns Label name of given channel, defaults to BD# or FD#
	string channels
	variable fastdac

	variable i=0
	variable nChannels
	string channel, buffer, xlabelfriendly = ""
	wave/t dacvalstr
	wave/t fdacvalstr
	nChannels = ItemsInList(channels, ",")
	for(i=0;i<nChannels;i+=1)
		channel = StringFromList(i, channels, ",")

		if (fastdac == 0)
			buffer = dacvalstr[str2num(channel)][3] // Grab name from dacvalstr
			if (cmpstr(buffer, "") == 0)
				buffer = "BD"+channel
			endif
		elseif (fastdac == 1)
			buffer = fdacvalstr[str2num(channel)][3] // Grab name from fdacvalstr
			if (cmpstr(buffer, "") == 0)
				buffer = "FD"+channel
			endif
		else
			abort "\"GetLabel\": Fastdac flag must be 0 or 1"
		endif

		if (cmpstr(xlabelfriendly, "") != 0)
			buffer = ", "+buffer
		endif
		xlabelfriendly += buffer
	endfor
	return xlabelfriendly + " (mV)"
end
