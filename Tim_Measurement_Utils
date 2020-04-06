//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////// Measurement Utilities   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAMeasurementUtility()
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


function get_numpts_from_sweeprate(fd, start, fin, sweeprate)
/// Convert sweeprate in mV/s to numptsx for fdacrecordvalues
	variable fd, start, fin, sweeprate
	variable numpts, adcspeed, numadc = 0, i
	wave fadcattr
	for (i=0; i<dimsize(fadcattr, 1)-1; i++) // Count how many ADCs are being measured
		if (fadcattr[i][2] == 48)
			numadc++
		endif
	endfor
	adcspeed = getfadcspeed(fd)
	numpts = round(abs(fin-start)*(adcspeed/numadc)/sweeprate)   // distance * steps per second / sweeprate
	return numpts
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
