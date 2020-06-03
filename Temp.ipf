#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Waves Average>  //TODO: what does this do?
#include <Function Grapher>
#include <FilterDialog> menus=0

//openHP34401Aconnection("dmm5", "GPIB0::5::INSTR", verbose=0)
//setup34401Adcvolts(dmm5, 1, 1)
//getls370status(ls370)

function testviread(fastdac)
	variable fastdac
	string buffer
	variable ret_count
//	writeinstr(fastdac,"BUFFER_RAMP,0,0,0,1,10,300,1\r")
//	writeinstr(fastdac,"INT_RAMP,0,0,0,1,10\r")
//	writeinstr(fastdac,"*RDY?\r")
//	visaSetReadTerm(fastdac, "\n")
	visaSetSerialEndIn(fastdac, 2)
   visaSetReadTermEnable(fastdac, 0)

	sleep/s 0.1
	variable i =0
	for (i=0; i<2; i++)
//		buffer = readinstr(fastdac)
		buffer = ""
		viRead(fastdac, buffer, 200, ret_count)
//		buffer = remove_rn(buffer)
		printf "Ret_count is %d, Buffer is: %s\r", ret_count, buffer
	endfor
	visaSetSerialEndIn(fastdac, 2)
end


function testcmd()

	variable/g multiplier
	string script = "1*1000", cmd = ""
	string wn = "testnumwave"
	wave datawave = $wn
	sprintf cmd, "%s = %s*%s", wn ,wn, script
	execute cmd
end


function pinchtest(bd, start, fin, channels, numpts, delay, ramprate, current_wave, cutoff_nA, gates_str)
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

function timer([reset])
	variable reset
	nvar/z tim_t0
	if (!nvar_Exists(tim_t0))
		variable/g tim_t0 = datetime
	elseif (reset != 0)
		variable/g tim_t0 = datetime
		return 0
	endif
	return datetime - tim_t0
end


function get_numpts_from_sweeprate(fd, start, fin, sweeprate)
/// Convert sweeprate in mV/s to numptsx for fdacrecordvalues
	variable fd, start, fin, sweeprate
	variable numpts, adcspeed, numadc = 0, i
	wave fadcattr
	for (i=0; i<dimsize(fadcattr, 1)-1; i++)
		if (fadcattr[i][2] == 48)
			numadc++
		endif
	endfor
	adcspeed = getfadcspeed(fd)
	numpts = round(abs(fin-start)*(adcspeed/numadc)/sweeprate)   // distance * steps per second / sweeprate
	return numpts
end


function ScanFastDAC(instrID, start, fin, channels, sweeprate, [ramprate, x_label, y_label, comments, nosave ,RCcutoff,numAverage,notch, ignore_positive]) //Units: mV
	// sweep one or more FastDac channels
	// channels should be a comma-separated string ex: "0,4,5"
	variable instrID, start, fin, sweeprate, ramprate, nosave, ignore_positive, RCcutoff, numAverage
	string channels, comments, notch, x_label, y_label
	variable i=0, j=0

	sc_openinstrconnections(0)

	if (paramisdefault(notch))
		notch = ""
	endif
	if (paramisdefault(comments))
		comments = ""
	endif

	ramprate = paramisdefault(ramprate) ? 1000 : ramprate

	if (paramisdefault(x_label))
		x_label = GetLabel(channels, fastdac=1)
	endif
	if (paramisdefault(y_label))
		y_label = ""
	endif

	variable numpts
	numpts = get_numpts_from_sweeprate(instrID, start, fin, sweeprate)

	string starts = "", fins = "" // Required for fdacRecordValues

	for(i=0; i<itemsInList(channels, ","); i++)
		Rampoutputfdac(instrID, str2num(stringfromlist(i, channels, ",")), start, ramprate=ramprate)
		starts = addlistitem(num2str(start), starts, ",")
		fins = addlistitem(num2str(fin), fins, ",")
	endfor
	starts = starts[0,strlen(starts)-2] // Remove comma at end
	fins = fins[0,strlen(fins)-2]	 		// Remove comma at end

	sc_sleep(0.5)
	InitializeWaves(start, fin, numpts, x_label=x_label, y_label=y_label, fastdac=1)

	fdacRecordValues(instrID,0,channels,starts,fins,numpts,ramprate=ramprate,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)
	if (nosave == 0)
  		SaveWaves(msg=comments, fastdac=1)
  	else
  		dowindow /k SweepControl
	endif

end



function ScanFastDAC2D(instrID, startx, finx, channelsx, sweeprate, starty, finy, channelsy, numptsy, [delayy, ramprate, x_label, y_label, comments, nosave ,RCcutoff,numAverage,notch, set_chargesensor, ignore_positive]) //Units: mV
	// 2D Scan for ALL FastDac Channels  (Does not work with BabyDac at all)
	// channels should be a comma-separated string ex: "0,4,5"
	variable instrID, startx, finx, sweeprate, starty, finy, numptsy, delayy, ramprate, nosave, ignore_positive, RCcutoff, numAverage, set_chargesensor
	string channelsx, channelsy, x_label, y_label, comments, notch
	variable i=0, j=0

	if (paramisdefault(notch))
		notch = ""
	endif
	if (paramisdefault(comments))
		comments = ""
	endif

	if (paramisdefault(x_label))
		x_label = GetLabel(channelsx, fastdac=1)
	endif
	if (paramisdefault(y_label))
		y_label = GetLabel(channelsy, fastdac=1)
	endif

	variable numptsx
	numptsx = get_numpts_from_sweeprate(instrID, startx, finx, sweeprate)


	delayy = paramisdefault(delayy) ? 0 : delayy
	ramprate = paramisdefault(ramprate) ? 1000 : ramprate


	// x Channels and startpoints.... Required for fdacRecordValues
	string startxs = "", finxs = ""
	for(i=0; i<itemsInList(channelsx, ","); i++)
		Rampoutputfdac(instrID, str2num(stringfromlist(i, channelsx, ",")), startx, ramprate=ramprate)
		startxs = addlistitem(num2str(startx), startxs, ",")
		finxs = addlistitem(num2str(finx), finxs, ",")
	endfor
	startxs = startxs[0,strlen(startxs)-2] // Remove comma at end
	finxs = finxs[0,strlen(finxs)-2]	 		// Remove comma at end

	// y Channels and startpoints.... Required for fdacRecordValues
	string startys = "", finys = ""
	for(i=0; i<itemsInList(channelsy, ","); i++)
		Rampoutputfdac(instrID, str2num(stringfromlist(i, channelsy, ",")), starty, ramprate=ramprate)
		startys = addlistitem(num2str(starty), startys, ",")
		finys = addlistitem(num2str(finy), finys, ",")
	endfor
	startys = startys[0,strlen(startys)-2] // Remove comma at end
	finys = finys[0,strlen(finys)-2]	 		// Remove comma at end


	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label= y_label, fastdac=1)
	sleep/s delayy
	variable setpointy, channely
	for(i=0; i<numptsy; i++)
		setpointy = starty + (i*(finy-starty)/(numptsy-1))
		for(j=0; j<itemsinlist(channelsy, ","); j++)
			channely = str2num(stringfromlist(j, channelsy, ","))
			rampoutputfdac(instrID, channely, setpointy, ramprate=ramprate)
		endfor

		/////////////////////////
		if (set_chargesensor == 1)
			variable x1=-726, y1=-183, x2=-639, y2=-250  // Will set the x channel along this line when correcting
			variable m, c, x, y=setpointy
			m = (y2-y1)/(x2-x1)
			c = y1-m*x1
			x = (y-c)/m
			if (x > 0 || x < -1000)
				abort "Rct point was going to be set to " + num2str(x)
			endif
			rampoutputfdac(instrID, str2num(channelsx[0]), x) // Only ramps first x channel (for now that is good enough for me, and will at least not do something crazy if I forget)
			CorrectChargeSensor(fd = instrID, fdchannel = 1, fadcchannel = 0, check=0, natarget=0.8)  // 1 is LCSQ on fastdac, 0 is fadc0
		endif
		/////////////////////////


		fdacRecordValues(instrID,i,channelsx,startxs,finxs,numptsx,delay=delayy,ramprate=ramprate,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)
	endfor
	if (nosave == 0)
  		SaveWaves(msg=comments, fastdac=1)
  	else
  		dowindow /k SweepControl
	endif

end


function ScanFastDACBabyDac2D(fd, bd, startx, finx, channelsx, sweeprate, starty, finy, channelsy, numptsy, [delayy, ramprate, x_label, y_label, comments, nosave ,RCcutoff,numAverage,notch, set_chargesensor, ignore_positive]) //Units: mV
	// 2D Scan for Fastdac on x and babydac on y
	// channels should be a comma-separated string ex: "0,4,5"
	variable fd, bd, startx, finx, sweeprate, starty, finy, numptsy, delayy, ramprate, nosave, ignore_positive, RCcutoff, numAverage, set_chargesensor
	string channelsx, channelsy, x_label, y_label, comments, notch
	variable i=0, j=0

	if (paramisdefault(notch))
		notch = ""
	endif
	if (paramisdefault(comments))
		comments = ""
	endif

	if (paramisdefault(x_label))
		x_label = GetLabel(channelsx, fastdac=1)
	endif
	if (paramisdefault(y_label))
		y_label = GetLabel(channelsy, fastdac=0)
	endif

	variable numptsx
	numptsx = get_numpts_from_sweeprate(fd, startx, finx, sweeprate)


	delayy = paramisdefault(delayy) ? 0 : delayy
	ramprate = paramisdefault(ramprate) ? 1000 : ramprate

	// x Channels and startpoints.... Required for fdacRecordValues
	string startxs = "", finxs = ""
	for(i=0; i<itemsInList(channelsx, ","); i++)
		Rampoutputfdac(fd, str2num(stringfromlist(i, channelsx, ",")), startx, ramprate=ramprate)
		startxs = addlistitem(num2str(startx), startxs, ",")
		finxs = addlistitem(num2str(finx), finxs, ",")
	endfor
	startxs = startxs[0,strlen(startxs)-2] // Remove comma at end
	finxs = finxs[0,strlen(finxs)-2]	 		// Remove comma at end


	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label= y_label, fastdac=1)
	sleep/s delayy
	variable setpointy, channely
	for(i=0; i<numptsy; i++)
		setpointy = starty + (i*(finy-starty)/(numptsy-1))
		rampmultiplebd(bd, channelsy, setpointy, ramprate=ramprate)
		/////////////////////////
		if (set_chargesensor == 1)
			variable x1=-795, y1=-160, x2=-430, y2=-300  // Will set the x channel along this line when correcting
			variable m, c, x, y=setpointy
			m = (y2-y1)/(x2-x1)
			c = y1-m*x1
			x = (y-c)/m
			if (x > 0 || x < -1000)
				abort "Rct point was going to be set to " + num2str(x)
			endif
			rampoutputfdac(fd, str2num(channelsx[0]), x) // Only ramps first x channel (for now that is good enough for me, and will at least not do something crazy if I forget)
			CorrectChargeSensor(fd = fd, fdchannel = 5, fadcchannel = 0, check=0, natarget=0.8)  // 5 is RCSQ on fastdac, 0 is fadc0
		endif
		/////////////////////////

		fdacRecordValues(fd,i,channelsx,startxs,finxs,numptsx,delay=delayy,ramprate=ramprate,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)
	endfor
	if (nosave == 0)
  		SaveWaves(msg=comments, fastdac=1)
  	else
  		dowindow /k SweepControl
	endif

end



//function noisemeasurement(fastdac, num)
//	variable fastdac, num
//	variable i=0
//
//	for (i=0; i < num; i += 1)
//		FD1D(fastdac, "0", 0, 0, 3000, 1e-3);
//		SetScale/I x 0,3*1.459,"", FastScan;
//		DSPPeriodogram/q/DBR=1000/DTRD/WIN=Hamming/SEGN={1000,0}/DEST=W_Periodogram FastScan
//		doupdate
//	endfor
//end

function periodogram(wave1d, [adcspeed, fd, adcnum])
	wave wave1d
	variable adcspeed, fd, adcnum

	duplicate/o wave1d periodogram_inwave


	if (paramisdefault(adcspeed) && paramisdefault(fd))
		abort "Must provide adcspeed or fastdac id"
	endif
	adcnum = paramisdefault(adcnum) ? 1 : adcnum
	adcspeed = paramisdefault(adcspeed) ? getfadcspeed(fd)/adcnum : adcspeed/adcnum

	SetScale/I x 0, numpnts(wave1d)/adcspeed, "Time /s", periodogram_inwave;
	display periodogram_inwave
	DSPPeriodogram/q/DBR=1000/DTRD/WIN=Hamming/SEGN={4000,0}/DEST=W_Periodogram periodogram_inwave
	SetScale/I x 0, numpnts(wave1d)/adcspeed, "Time /s", periodogram_inwave;
	display w_periodogram
	Label bottom "Frequency /Hz"


end




////////////////////////////////////// MACROS
//function Scan3DTemplate()
//	nvar fastdac, bd6
//	string buffer
//	variable i, j, k
//	make/o/free Var1 = {}
//	make/o/free Var2 = {}
//	make/o/free Var3 = {}
//
//	i=0; j=0; k=0
//	do // Loop to change k var3
//		rampmultiplebd(bd6, "", Var3[k])
//		do	// Loop for change j var2
//			rampmultiplebd(bd6, "", Var2[j])
//			do // Loop for changing i var1 and running scan
//				rampmultiplebd(bd6, "", Var1[i])
//				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]
//				//Correct CS etc
//				//SCAN HERE
//
//
//				i+=1
//			while (i < numpnts(Var1))
//			i=0
//			j+=1
//		while (j < numpnts(Var2))
//		j=0
//		k+=1
//	while (k< numpnts(Var3))
//	notify("Finished all scans") // Currently not working
//end


function fri14thfeb(fastdac, bd6, srs1)
	variable fastdac, bd6, srs1
	variable i, j, k
	string buffer = "", comments = ""

	sc_openinstrconnections(0)
	setsrsamplitude(srs1, 1000)
	setsrstimeconst(srs1, 0.03)
	setsrsfrequency(srs1, 111.11)


//	print "STARTING TO MEASURE RIGHT SIDE ======================================================"
//	for (i=0; i < 4; i++) // Ramp all left side fastdacs back to zero
//		rampoutputfdac(fastdac, i, 0)
//	endfor
//	rampmultiplebd(bd6, "4", 0) // Ramp LCSS to zero
//
//	make/o/free Var1 = {-100, -200, -300, -400, -500} // RCB  BD6
//	make/o/free Var2 = {0, -100, -200, -300, -400} // RP FD7
//	make/o/free Var3 = {-300, -800} //RCSQ FD5
//
//	i=0; j=0; k=0
//	do // Loop to change k var3
//		rampoutputfdac(fastdac, 5, Var3[k])
//		do	// Loop for change j var2
//			rampoutputfdac(fastdac, 7, var2[j])
//			do // Loop for changing i var1 and running scan
//				rampmultiplebd(bd6, "6", var1[i])
//				sprintf buffer, "Starting scan at RCB = %.1fmV, RP = %.1fmV, RCSQ = %.1fmV\r", Var1[i], Var2[j], var3[k]
//				sprintf comments, "2dconductance, feb14array2, right side, RCB = %.1fmV, RP = %.1fmV, RCSQ = %.1fmV", var1[i], var2[j], var3[k]
//				ScanFastDAC2D(fastdac, 0, -1400, "4", 200, 0, -500, "6", 51, delayy=0.3, ramprate=1000, comments=comments)
//				i+=1
//			while (i < numpnts(Var1))
//			i=0
//			j+=1
//		while (j < numpnts(Var2))
//		j=0
//		k+=1
//	while (k< numpnts(Var3))
//


	print "STARTING TO MEASURE LEFT SIDE ======================================================"
	for (i=4; i < 8; i++) // Ramp all right side fastdacs back to zero
		rampoutputfdac(fastdac, i, 0)
	endfor
	rampmultiplebd(bd6, "6", 0) // Ramp RCB to zero


	make/o/free Var1 = {0, -25, -50, -75, -100, -125, -150, -200} // LP
	make/o/free Var2 = {-100, -150, -200, -250} // LCSS (LCSQ)
	make/o/free Var3 = {0} //


	i=0; j=0; k=0
	do // Loop to change k var3
//		rampmultiplebd(bd6, "", Var3[k])
		do	// Loop for change j var2
			rampmultiplebd(bd6, "4", Var2[j])
			rampoutputfdac(fastdac, 1, -900-2*var2[j], ramprate=1000)
			do // Loop for changing i var1 and running scan
				rampoutputfdac(fastdac, 3, var1[i], ramprate=1000)
				sprintf buffer, "Starting scan at LP = %.1fmV, LCSS = %.1fmV, LCSQ = %.1fmV\r", Var1[i], Var2[j], -900-2*Var2[j]
				sprintf comments, "2dconductance, feb14array1, left side, LP = %.1fmV, LCSS = %.1fmV, LCSQ = %.1fmV", var1[i], var2[j], -900-2*Var2[j]
				ScanFastDAC2D(fastdac, 0, -800, "0", 200, 0, -800, "2", 41, delayy=0.3, ramprate=1000, comments=comments)

				i+=1
			while (i < numpnts(Var1))
			i=0
			j+=1
		while (j < numpnts(Var2))
		j=0
		k+=1
	while (k< numpnts(Var3))
//	notify("Finished all scans")  // Not working

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



function ScanfastdacRepeat(instrID, start, fin, channels, sweeprate, numy, [delayy, ramprate, x_label, y_label, comments, nosave ,RCcutoff,numAverage,notch, ignore_positive, alternate, step_something, starty, finy])
	// 1D repeat (can additionally chose to run the step something section)
	variable instrID, start, fin, sweeprate, numy, delayy, ramprate, nosave, ignore_positive, RCcutoff, numAverage, alternate, step_something, starty, finy
	string channels, comments, notch, x_label, y_label
	variable i=0, j=0

	if (!paramisdefault(alternate))
		abort "Not implemented alternating direction scans yet"
	endif


	if (paramisdefault(notch))
		notch = ""
	endif
	if (paramisdefault(comments))
		comments = ""
	endif

	ramprate = paramisdefault(ramprate) ? 1000 : ramprate

	if (paramisdefault(x_label))
		x_label = GetLabel(channels, fastdac=1)
	endif
	if (paramisdefault(y_label))
		y_label = "Repeats"
	endif
	starty = paramisdefault(starty) ? 0 : starty
	finy = paramisdefault(finy) ? numy : finy
	delayy = paramisdefault(delayy) ? 0.1 : delayy

	variable numpts
	numpts = get_numpts_from_sweeprate(instrID, start, fin, sweeprate)



	string starts = "", fins = "" // Required for fdacRecordValues

	for(i=0; i<itemsInList(channels, ","); i++)
		Rampoutputfdac(instrID, str2num(stringfromlist(i, channels, ",")), start, ramprate=ramprate)
		starts = addlistitem(num2str(start), starts, ",")
		fins = addlistitem(num2str(fin), fins, ",")
	endfor
	starts = starts[0,strlen(starts)-2] // Remove comma at end
	fins = fins[0,strlen(fins)-2]	 		// Remove comma at end

	////////////// VARIABLES FOR STEP SOMETHING //////////////
	make/o/free var1 = {-100, -200, -300, -400, -500, -600, -700, -800, -900, -1000}

	//////////////////////////////////////////////////////////



	sc_sleep(0.3)
	InitializeWaves(start, fin, numpts, x_label=x_label, y_label=y_label, starty=starty, finy=finy, numptsy=numy, fastdac=1)
	for (j=0; j<numy; j++)
		if (step_something == 1)
			// STEP SOMETHING HERE
			rampoutputfdac(instrID, 7, var1[j])
			CorrectChargeSensor(fd=instrID, fdchannel=1, fadcchannel=0, i=0, check=0, natarget=0.8, direction=1)
		endif
		fdacRecordValues(instrID,j,channels,starts,fins,numpts,delay=delayy, ramprate=ramprate,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)

	endfor
	if (nosave == 0)
  		SaveWaves(msg=comments, fastdac=1)
  	else
  		dowindow /k SweepControl
	endif

end



function CenterOnTransitionFD(fd, fdacchannel, fadcchannel, [setpoint, width, setchargesensor, natarget])
//// Does small 1D scan and sets fdacchannel to be center of transition. fadchannel should be charge sensor channel
	variable fd, fdacchannel, fadcchannel, setpoint, width, setchargesensor, natarget
	wave transitionwave

	wave/t old_fdacvalstr
	variable oldfdval, newfdval

	oldfdval = str2num(old_fdacvalstr[fdacchannel])
	setpoint = paramisdefault(setpoint) ? oldfdval : setpoint
	width = paramisdefault(width) ? 40 : width
	natarget = paramisdefault(natarget) ? 0.8 : natarget

	if (setchargesensor == 1)
		rampoutputfdac(fd, fdacchannel, setpoint)
		CorrectChargeSensor(fd=fd, fdchannel=5, fadcchannel=0, natarget=natarget)
	endif

	ScanFastDAC(fd, setpoint-width, setpoint+width, num2str(fdacchannel), width, ramprate=500, nosave=1, ignore_positive=1) // second 'width' is sweeprate so it takes 2s
	wave transitionwave = $"ADC"+num2str(fadcchannel)

	newfdval = FindTransitionMid(transitionwave)

	if (numtype(newfdval) == 0 && abs(newfdval-setpoint) < 500 && newfdval < 100 && newfdval > -6000) // Make sure reasonable newfdval
		rampOutputfdac(fd,fdacchannel,newfdval)
		printf "Corrected FD%d to %.1fmV\r", fdacchannel, newfdval
	else
		rampOutputfdac(fd,fdacchannel,oldfdval)
		printf "Reverted to old FD%d of %.1fmV instead of ramping to %.1fmV\r", fdacchannel, oldfdval, newfdval
		newfdval = oldfdval
	endif
	if (setchargesensor == 1)
		CorrectChargeSensor(fd=fd, fdchannel=5, fadcchannel=0, natarget=natarget)
	endif
	return newfdval
end
//
//function CenterOnTransition(bdx, [bdxsetpoint, fdx, width]) //centres bdx on transition by default around where it currently is, otherwise near setpoint, zeroing fdx if provided.
//	string bdx, fdx
//	variable bdxsetpoint, width
//
//	nvar fastdac, bd6
//	wave/t old_dacvalstr
//	variable oldSDR, newSDR
//	oldSDR = str2num(old_dacvalstr[str2num(bdx)])
//	if (!paramisdefault(fdx))
//		rampfd(fastdac, fdx, 0)
//	endif
//	width = paramisdefault(width) ? 40 : width
//	bdxsetpoint = paramisdefault(bdxsetpoint) ? oldSDR : bdxsetpoint
//	wave fd_0adc //Currently hard coded to use FDadc0 as CS input
//	ScanBabyDAC(bd6, bdxsetpoint-width, bdxsetpoint+width, bdx, 201, 0.001, 1000, nosave=1)
//	newSDR = FindTransitionMid(fd_0adc)
//	if (numtype(newSDR) == 0 && newSDR > -2000 && newSDR < 0) // If reasonable then center there
//		rampmultiplebd(bd6, bdx, newSDR)
//		printf "Corrected BD%s to %.1fmV\r", bdx, newSDR
//	else
//		rampmultiplebd(bd6, bdx, oldSDR)
//		printf "Reverted to old BD%s of %.1fmV\r", bdx, oldSDR
//		newSDR = oldSDR
//	endif
//	setchargesensorfd(fastdac, bd6, setpoint = str2num(old_dacvalstr[2])/300*0.8) //channel 2 is CSbias
//	return newSDR
//end



function steptempscanSomething()
	nvar bd6, srs1, fastdac
	svar ls370

	make/o targettemps = {300, 250, 200, 150, 100, 75, 50, 40, 30, 20}
	make/o heaterranges = {3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 1, 1, 1, 1}
	setLS370exclusivereader(ls370,"ld_mc")

	make/o/free RCT = {-602, -550}
	make/o/free RCSS = {-230, -250}
	make/o/free sweeprate = {10, 20, 50, 100}
	string comment
	variable i=0, j=0, k=0
	do
		setLS370PIDcontrol(ls370,6,targettemps[i],heaterranges[i])
		sc_sleep(2.0)
		WaitTillTempStable(ls370, targettemps[i], 3, 10, 0.10)
		timsleep(60.0)
		print "MEASURE AT: "+num2str(targettemps[i])+"mK"
//		notify( "MEASURE AT: "+num2str(targettemps[i])+"mK")
		//Scan Here
		for (j=0; j<numpnts(RCT); j++)
			for(k=0; k<numpnts(sweeprate); k++)
				sprintf comment, "right side, dcbias, 2drepeat, sweeping with RP, rccutoff=50, transition width vs fridge temp, position=%d", j
				printf "RCT = %dmV, RCSS = %dmV, Sweeprate = %dmV/s, Current temp is %.1fmK\r", RCT[j], RCSS[j], sweeprate[k], getls370temp(ls370,"mc")*1000
				rampOutputfdac(fastdac, 7, -1250)
				rampOutputfdac(fastdac, 4, RCT[j])
				rampOutputfdac(fastdac, 6, RCSS[j])
				centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
				ScanFastDACrepeat(fastdac, -1250+30, -1250-30, "7", sweeprate[k], 50, delayy=0.5, ramprate=1000, comments=comment, nosave=0, rccutoff=50)
				rampOutputfdac(fastdac, 7, -1250)
				timsleep(60)
			endfor
		endfor

		i+=1
	while ( i<numpnts(targettemps) )

	// kill temperature control
//	turnoffls370heater(ls370)
	resetLS370exclusivereader(ls370)
	timsleep(60.0*30)

	// 	ScanHere for base temp
	print "MEASURE AT: "+num2str(getls370temp(ls370,"mc")*1000)+"mK"
	for (j=0; j<numpnts(RCT); j++)
		for(k=0; k<numpnts(sweeprate); j++)
			sprintf comment, "right side, transition, 2drepeat, sweeping with RP, rccutoff=50, transition width vs fridge temp, position=%d", j
			printf "RCT = %dmV, RCSS = %dmV, Sweeprate = %dmV/s, Current temp is %.1fmK\r", RCT[j], RCSS[j], sweeprate[k], getls370temp(ls370,"mc")*1000
			rampOutputfdac(fastdac, 7, -1250)
			rampOutputfdac(fastdac, 4, RCT[j])
			rampOutputfdac(fastdac, 6, RCSS[j])
			centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
			ScanFastDACrepeat(fastdac, -1250+30, -1250-30, "7", sweeprate[k], 50, delayy=0.5, ramprate=1000, comments=comment, nosave=0, rccutoff=50)
			rampOutputfdac(fastdac, 7, -1250)
		endfor
	endfor

end


function step_sweeprate()
	nvar fastdac, bd6
	string buffer, comment
	variable i, j, k
	make/o/free var2 = {0}
	make/o/free var3 = {0}
	make/o/free sweeprate = {200, 100, 50, 30, 20, 10, 5}

	i=0; j=0; k=0
	do // Loop to change k var3
//		rampmultiplebd(bd6, "", Var3[k])
		do	// Loop for change j var2
//			rampmultiplebd(bd6, "", Var2[j])
			do // Loop for changing i var1 and running scan

//				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]
				printf "Starting scan with sweeprate = %dmV/s\r", sweeprate[i]
				sprintf comment, "sweeprate, transition, 2drepeat, rccutoff=100, sweeprate=%dmV/s", sweeprate[i]
				ScanFastDACrepeat(fastdac, -1250+30, -1250-30, "7", sweeprate[i], 30, delayy=0.5, ramprate=1000, comments=comment, rccutoff=100, nosave=0)
				i+=1
			while (i < numpnts(sweeprate))
			i=0
			j+=1
		while (j < numpnts(Var2))
		j=0
		k+=1
	while (k< numpnts(Var3))
end


function Step_temp_DCbias()
	nvar bd6, srs1, fastdac
	svar ls370

	setsrsamplitude(srs1, 0)

	make/o targettemps = {300, 250, 200, 150, 100, 75, 50, 40, 30, 20}
	make/o heaterranges = {3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 1, 1, 1, 1}
	make/o DCbias 		=	{600, 500, 450, 400, 300, 200, 150, 100, 100, 100}
	setLS370exclusivereader(ls370,"ld_mc")

	make/o/free RCT = {-602, -550}
	make/o/free RCSS = {-230, -250}
	make/o/free sweeprate = {100}
	string comment
	variable i=0, j=0, k=0
	do
		setLS370PIDcontrol(ls370,6,targettemps[i],heaterranges[i])
		sc_sleep(2.0)
		WaitTillTempStable(ls370, targettemps[i], 3, 10, 0.10)
		timsleep(60.0)
		print "MEASURE AT: "+num2str(targettemps[i])+"mK"
//		notify( "MEASURE AT: "+num2str(targettemps[i])+"mK")
		//Scan Here
		for (j=0; j<numpnts(RCT); j++)
			for(k=0; k<numpnts(sweeprate); k++)
				sprintf comment, "right side, dcbias, 2drepeat, notch=(60,120), rccutoff=100, RCT = %dmV, RCSS = %dmV, Sweeprate = %dmV/s, DCbiasMax = %dmV, Starting temp is %.1fmK\r", RCT[j], RCSS[j], sweeprate[k], DCbias[i], getls370temp(ls370,"mc")*1000
				print comment
				print ""
				rampOutputfdac(fastdac, 7, -1250)
				rampOutputfdac(fastdac, 4, RCT[j])
				rampOutputfdac(fastdac, 6, RCSS[j])
				centerontransitionfd(fastdac, 4, 0, width=30, setchargesensor=1)
				ScanFastDACBabyDac2D(fastdac, bd6, -1250-40, -1250+40, "7", sweeprate[k], -DCbias[i], +DCbias[i], "12", 101, nosave=0, delayy=0.5, ramprate=1000, y_label="DCbias/mV(10Mohm)", comments=comment, notch="60,120", rccutoff=100)
				rampOutputfdac(fastdac, 7, -1250)
				timsleep(60)
			endfor
		endfor

		i+=1
	while ( i<numpnts(targettemps) )

	// kill temperature control
//	turnoffls370heater(ls370)
	resetLS370exclusivereader(ls370)
	timsleep(60.0*30)

	// 	ScanHere for base temp
	print "MEASURE AT: "+num2str(getls370temp(ls370,"mc")*1000)+"mK"
	for (j=0; j<numpnts(RCT); j++)
		for(k=0; k<numpnts(sweeprate); k++)
				sprintf comment, "right side, dcbias, 2drepeat, notch=(60,120), rccutoff=100, RCT = %dmV, RCSS = %dmV, Sweeprate = %dmV/s, DCbiasMax = %dmV, Starting temp is %.1fmK\r", RCT[j], RCSS[j], sweeprate[k], DCbias[i], getls370temp(ls370,"mc")*1000
				print comment
				print ""
				rampOutputfdac(fastdac, 7, -1250)
				rampOutputfdac(fastdac, 4, RCT[j])
				rampOutputfdac(fastdac, 6, RCSS[j])
				centerontransitionfd(fastdac, 4, 0, width=30, setchargesensor=1)
				ScanFastDACBabyDac2D(fastdac, bd6, -1250-40, -1250+40, "7", sweeprate[k], -100, +100, "12", 101, nosave=0, delayy=0.5, ramprate=1000, y_label="DCbias/mV(10Mohm)", comments=comment, notch="60,120", rccutoff=100)
				rampOutputfdac(fastdac, 7, -1250)
				timsleep(60)
			endfor
	endfor

end





function Scan_entropy_forever()
	nvar fastdac, bd6, srs1
	svar ls370
	string buffer, comment
	variable i, j, k
	make/o/free var2 = {0}
	make/o/free var3 = {0}
	make/o/free var1 = {1}
	killvisa()
	sc_openinstrconnections(0)
	setls370exclusivereader(ls370, "ld_mc")
//	ScanFastDac2DLine(fastdac, -1350, -1150, "7", 1, -620, -590, "4", 31, 0.5, 50, comments="2dlinecut, 0-1 transition, close to normal position only, RCT vs RP, notch=(60,120), rccutoff=100", x1=-1200, y1=-611.5, x2=-1300, y2=-596, rampratex=1000, rampratey=1000, linecut=1, followtolerance=0, notch="60, 120", RCcutoff=100)


	variable scan_duration = 600 //in seconds
	variable width = 60 //mV (RP*0.16)
	variable ramprate = 1000 // ramping back between scans mV/s
	variable delayy = 0.5 // settle time in s before next sweep
	variable num_repeats, startx, finx
	variable sweeprate = 1
	variable srsout = 1000
	variable centerx
//	variable start_center = -1250
//	centerx = start_center
//	ramp_all_dacs_and_back(setpoint=0)
	centerx = centerontransitionfd(fastdac, 7, 0, width=200, setchargesensor=1)
	i=0; j=0; k=0
//	do // Loop to change k var3
//		rampmultiplebd(bd6, "", Var3[k])
//		do	// Loop for change j var2
//			rampmultiplebd(bd6, "", Var2[j])
			do // Loop for changing i var1 and running scan

//				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]

//				num_repeats = round(scan_duration*sweeprate[i]/scan_width) // Simple version
				num_repeats = round(scan_duration/(width/sweeprate+width/ramprate + delayy)) // Complex version including sweep back and delayy


				if (num_repeats < 2)  // Scanrepeat doesn't like 1D waves I think.
					num_repeats = 2
				endif
				rampOutputfdac(fastdac,7,centerx)
//				centerontransitionfd(fastdac, 4, 0, width=200, setchargesensor=1)
				centerx = centerontransitionfd(fastdac, 7, 0, width=60, setchargesensor=1)
				setsrsamplitude(srs1, srsout)
				sprintf comment, "time stability at multiple RCT, i=%d, entropy, 2drepeat, rccutoff=20, sweeprate=%dmV/s, num_repeats=%d, width = %d", i, sweeprate, num_repeats, width
				print comment + "\r"

				ScanFastDACrepeat(fastdac, centerx-width/2, centerx+width/2, "7", sweeprate, num_repeats, nosave=0, delayy=delayy, ramprate=ramprate, comments=comment, rccutoff=20)
//				timsleep(30) // let temp stablize again after lakeshore has to cycle through to getstatus
//				DCbiasRepeat(sweeprate = sweeprate[i], numrepeats = num_repeats)

				timsleep(30)
				i+=1
			while (i < 50)
//			DCbiasScan(numrows=601, max_bias=400, RCT=-4400)
//			ramp_all_dacs_and_back(setpoint=0)
//			chargesensoroffsetscan()
//			resetls370exclusivereader(ls370)
//			timsleep(60)
//			setls370exclusivereader(ls370, "ld_mc")
//
//			i=0
//			j+=1
//		while (j < numpnts(Var2))
//		while (1)  ///////////////////////////////// This makes it run forever!!
//		j=0
//		k+=1
//	while (k< numpnts(Var3))
end

function ramp_all_dacs_and_back([setpoint])
	variable setpoint
	variable fastdac, babydac
	print "Beginning Ramp all Dacs"

	setpoint = paramisdefault(setpoint) ? 0 : setpoint
	if ((setpoint < -1000) || (setpoint > 100))
		abort "Aborting: was about to ramp all gates below 1V or above 100mV"
	endif

//	killvisa()
//	sc_openinstrconnections(0)

	//Dacval waves
	wave/t dacvalstr
	wave/t fdacvalstr


	//Temporary storage of dacvals
	duplicate/o/t/free dacvalstr currentdacs
	duplicate/o/t/free fdacvalstr currentfdacs


	//Set all dacs to 0
	dacvalstr[][1] = num2str(setpoint)
	fdacvalstr[][1] = num2str(setpoint)

	update_BabyDAC("ramp")
	update_fdac("fdacramp")

	timsleep(30)

	dacvalstr = currentdacs[p]
	fdacvalstr = currentfdacs[p]

	update_BabyDAC("ramp")
	update_fdac("fdacramp")
	print "Finished Ramping back to starting Values"


end

function mar12_stability_test()
	nvar fastdac
//	DCbiasScan(numrows=601, max_bias=400, RCT=-4400)
	variable i=0
	setup_standard_entropy()
	do
		ramp_all_dacs_and_back()
		printf "Starting set [%d] of 10 repeats of entropy measurements", i
		Scan_entropy_forever()  // Currently set only to be 10x 5min scans (12th Mar)
		i++
	while (1)

end

function Scan_entropy_forever_left()
	nvar fastdac, bd6, srs1
	svar ls370
	string buffer, comment
	variable i, j, k
	make/o/free var2 = {0}
	make/o/free var3 = {0}
	make/o/free var1 = {1}
	killvisa()
	sc_openinstrconnections(0)
	setls370exclusivereader(ls370, "ld_mc")
//	ScanFastDac2DLine(fastdac, -1350, -1150, "7", 1, -620, -590, "4", 31, 0.5, 50, comments="2dlinecut, 0-1 transition, close to normal position only, RCT vs RP, notch=(60,120), rccutoff=100", x1=-1200, y1=-611.5, x2=-1300, y2=-596, rampratex=1000, rampratey=1000, linecut=1, followtolerance=0, notch="60, 120", RCcutoff=100)


	variable scan_duration = 1200 //in seconds
	variable scan_width = 80 //mV (RP*0.16)
	variable ramprate = 1000 // ramping back between scans mV/s
	variable delayy = 0.5 // settle time in s before next sweep
	variable num_repeats, startx, finx
	variable sweeprate = 0.5
	variable srsout = 500
	startx = -990-scan_width/2
	finx = -990+scan_width/2


	i=0; j=0; k=0
//	do // Loop to change k var3
//		rampmultiplebd(bd6, "", Var3[k])
//		do	// Loop for change j var2
//			rampmultiplebd(bd6, "", Var2[j])
			do // Loop for changing i var1 and running scan

//				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]

//				num_repeats = round(scan_duration*sweeprate[i]/scan_width) // Simple version
				num_repeats = round(scan_duration/(scan_width/sweeprate+scan_width/ramprate + delayy)) // Complex version including sweep back and delayy


				if (num_repeats < 2)  // Scanrepeat doesn't like 1D waves I think.
					num_repeats = 2
				endif
				rampOutputfdac(fastdac,3,-990)
				centerontransitionfd(fastdac, 0, 0, width=20, setchargesensor=1)
				setsrsamplitude(srs1, srsout)
				sprintf comment, "ramp_repeat gates then sweep, transition, entropy, 2drepeat, rccutoff=100, notch=(60,120), sweeprate=%dmV/s, num_repeats=%d, scan_width = %d", sweeprate, num_repeats, scan_width
				print comment + "\r"

				ScanFastDACrepeat(fastdac, startx, finx, "3", sweeprate, num_repeats, nosave=0, delayy=delayy, ramprate=ramprate, comments=comment, rccutoff=100, notch="60,120")
				timsleep(30) // let temp stablize again after lakeshore has to cycle through to getstatus
//				DCbiasRepeat(sweeprate = sweeprate[i], numrepeats = num_repeats)
//				DCbiasScan(numrows=201)
				timsleep(30)
				i+=1
			while (i < 5)
//			chargesensoroffsetscan()
//			resetls370exclusivereader(ls370)
//			timsleep(60)
//			setls370exclusivereader(ls370, "ld_mc")
//
//			i=0
//			j+=1
//		while (j < numpnts(Var2))
//		while (1)  ///////////////////////////////// This makes it run forever!!
//		j=0
//		k+=1
//	while (k< numpnts(Var3))
end


function Scan_entropy_forever2()
	nvar fastdac, bd6, srs1
	svar ls370
	string buffer, comment
	variable i, j, k
	make/o/free var2 = {-550, -540, -530, -520, -510, -500, -490}  // HQPC gates  (previously -515mV)
	make/o/free var1 = {100, 200, 300, 400, 500, 600, 700}  // SRS bias (mV)
	//
	make/o/free var3 = {1}
//	make/o/free sweeprate = {1}
	killvisa()
	sc_openinstrconnections(0)
	setls370exclusivereader(ls370, "ld_mc")

	variable scan_duration = 600 //in seconds
	variable scan_width = 60 //mV (RP*0.16)
	variable ramprate = 1000 // ramping back between scans mV/s
	variable delayy = 0.5 // settle time in s before next sweep
	variable sweeprate = 1
	variable num_repeats, startx, finx
	startx = -1250-scan_width/2
	finx = -1250+scan_width/2


	i=0; j=0; k=0
	do
		do // Loop to change k var3
	//		rampmultiplebd(bd6, "", Var3[k])
			do	// Loop for change j var2
				rampOutputfdac(fastdac,0,var2[j]) // HQPC gates
				rampOutputfdac(fastdac,2,var2[j])
				centerontransitionfd(fastdac, 4, 0, width=40, setchargesensor=1)
				DCbiasScan()
				setsrsamplitude(srs1, var1[i])	//ACbias
	//			rampmultiplebd(bd6, "", Var2[j])
				do // Loop for changing i var1 and running scan

	//				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]

	//				num_repeats = round(scan_duration*sweeprate[i]/scan_width) // Simple version
					num_repeats = round(scan_duration/(scan_width/sweeprate+scan_width/ramprate + delayy)) // Complex version including sweep back and delayy


					if (num_repeats < 2)  // Scanrepeat doesn't like 1D waves I think.
						num_repeats = 2
					endif
					rampOutputfdac(fastdac,7,-1250)
					centerontransitionfd(fastdac, 4, 0, width=40, setchargesensor=1)
					setsrsamplitude(srs1, var1[i]*var3[k])
					sprintf comment, "HQPC ACbias scans, transition, entropy, 2drepeat, rccutoff=100, notch=(60,120), num_repeats=%d, scan_width = %d, HQPC = %f/mV, SRSbias = %d/mV", num_repeats, scan_width, var2[j], var1[i]*var3[k]
					print comment + "\r"
					ScanFastDACrepeat(fastdac, startx, finx, "7", sweeprate, num_repeats, nosave=0, delayy=delayy, ramprate=ramprate, comments=comment, rccutoff=100, notch="60,120")
					timsleep(30) // let temp stablize again after lakeshore has to cycle through to getstatus
	//				DCbiasRepeat(sweeprate = sweeprate[i], numrepeats = num_repeats)
					i+=1
				while (i < numpnts(Var1))
				i=0
				j+=1
			while (j < numpnts(Var2))
	//		while (1)  ///////////////////////////////// This makes it run forever!!
			chargesensoroffsetscan()
			resetls370exclusivereader(ls370)
			timsleep(60)
			setls370exclusivereader(ls370, "ld_mc")

			j=0
			k+=1
		while (k< numpnts(Var3))
		k=0
	while (1)  ///////////////////////////////// This makes it run forever!!


end


function Scan_entropy_along_transition()
	nvar fastdac, bd6, srs1
	svar ls370
	string buffer, comment
	variable i, j, k

//x1=-1263.3, y1=-599.5, x2=-1869.7, y2=-505

	make/o/free var2 = {0}
	make/o/free var2a = {0}
	make/o/free var3 = {0,0,0,0,0}
//	make/o/free var1 = {-500, -475, -450, -430, -410, -400, -390, -380, -370, -360, -350, -340, -330}//{-610, -600, -590, -570, -550, -530, -510, -500, -490, -480, -470, -460, -450, -440, -430, -420, -410, -400}
	make/o/free var1 = {-4550} //{-4600, -4550, -4500, -4450} //, -4400, -4350, -4300}//{-610, -600, -590, -570, -550, -530, -510, -500, -490, -480, -470, -460, -450, -440, -430, -420, -410, -400}
//	make/o/free var1 = {-240, -235, -230, -225, -220}
//	make/o/free var1 = {-4800, -4750, -4700, -4650, -4600, -4550, -4500, -4450, -4400}//



	killvisa()
	sc_openinstrconnections(0)
	setls370exclusivereader(ls370, "ld_mc")

	variable scan_duration = 600 //in seconds
	variable scan_width = 60 //mV (RP*0.16)
	variable ramprate = 1000 // ramping back between scans mV/s
	variable delayy = 0.5 // settle time in s before next sweep
	variable num_repeats, startx, finx, centerx
	variable sweeprate=1
	variable fdchannel = 4
	variable srsamplitude = 1000
//	DCbiasScan(numrows=401)

	setsrsamplitude(srs1, srsamplitude)
	rampmultiplebd(bd6, "12", 0)  //DCbias off


	i=0; j=0; k=0
	do
		do // Loop to change k var3
	//		rampmultiplebd(bd6, "", Var3[k])
			do	// Loop for change j var2

	//			rampmultiplebd(bd6, "", Var2[j])
				do // Loop for changing i var1 and running scan

	//				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]

	//				num_repeats = round(scan_duration*sweeprate[i]/scan_width) // Simple version

//					if (abs(var1[i]) < 450)
//						scan_width = 150  // Needs to be wider for gamma broadened
//					elseif (abs(var1[i]) < 500)
//						scan_width = 100
//					else
//						scan_width = 80  // Not so wide when very closed off
//					endif

					num_repeats = round(scan_duration/(scan_width/sweeprate+scan_width/ramprate + delayy)) // Complex version including sweep back and delayy
//					centerx = (var1[i]+796)/-0.1557  // Line through ((-1870, -505), (-1263, -599.5))
//					centerx = (var1[i]+664)/-0.17075  // equation of line through (-1240.8, -453) and (-1738.6, -368)
					centerx = (var1[i]+6674)/-1.73  // equation of line through (-1418.3, -4220) and (-1175.6, -4640)
//					centerx = (var1[i]+89518/279)/-(20/279)  // equation of line through (-1100, -242) and (-1379, -222)
//					centerx = (var1[i]+7369)/-1.664  //equation of line through (-1363.5, -5100) and (-1724, -4500)



					if (num_repeats < 2)  // Scanrepeat doesn't like 1D waves I think.
						num_repeats = 2
					endif
					rampoutputfdac(fastdac, fdchannel, var1[i])
					rampOutputfdac(fastdac,7,centerx)
					centerx = centerontransitionfd(fastdac, 7, 0, width=200, setchargesensor=1)
					centerx = centerontransitionfd(fastdac, 7, 0, width=30, setchargesensor=1)
					startx = centerx-scan_width/2
					finx = centerx+scan_width/2
//					sprintf comment, "RCT small steps, 100ms time const, slow sample rate, lower bias repeat scans along transition, transition, entropy, 2drepeat, along 0-1 transition, rccutoff=20, num_repeats=%d, scan_width = %d", num_repeats, scan_width
//					sprintf comment, "100ms time const lower bias repeat scans along transition, transition, entropy, 2drepeat, along 0-1 transition, rccutoff=100, notch=(60,120), num_repeats=%d, scan_width = %d", num_repeats, scan_width

//					print comment + "\r"


					scan_entropy_forever()

//					ScanFastDACrepeat(fastdac, startx, finx, "7", sweeprate, num_repeats, nosave=0, delayy=delayy, ramprate=ramprate, comments=comment, rccutoff=20)
//					ScanFastDACrepeat(fastdac, startx, finx, "7", sweeprate, num_repeats, nosave=0, delayy=delayy, ramprate=ramprate, comments=comment, rccutoff=100, notch="60,120")
//					timsleep(30) // let temp stablize again after lakeshore has to cycle through to getstatus


	//				DCbiasRepeat(sweeprate = sweeprate[i], numrepeats = num_repeats)
//
					i+=1
				while (i < numpnts(var1))
				i=0
				j+=1
			while (j < numpnts(Var2))
	//		while (1)  ///////////////////////////////// This makes it run forever!!

//
//			DCbiasScan(numrows=1001, max_bias=400, RCT=-4400)
//			chargesensoroffsetscan()
			resetls370exclusivereader(ls370)
			timsleep(60)
			setls370exclusivereader(ls370, "ld_mc")

			j=0
			k+=1
		while (k< numpnts(Var3))
		DCbiasScan(numrows=1001, max_bias=400, RCT=-4400)
		k=0
	while (1)  ///////////////////////////////// This makes it run forever!!


end




function Scan_entropy_acbias()
	nvar fastdac, bd6, srs1, srs3, magy
	svar ls370
	string buffer, comment
	variable i, j, k
	make/o/free var2 = {0}
	make/o/free var3 = {200, 200}
//	make/o/free acbias = {300, 400, 500, 600, 700, 800, 900}
//	make/o/free acbias = {300, 900, 400, 800, 500, 700, 600}  // so if there is a variation with time it won't look like a trend
	make/o/free acbias = {500, 400, 300, 200, 100}  // so if there is a variation with time it won't look like a trend
	killvisa()
	sc_openinstrconnections(0)
	setls370exclusivereader(ls370, "ld_mc")

//	ScanFastDac2DLine(fastdac, -1350, -1150, "7", 1, -620, -590, "4", 31, 0.5, 50, comments="2dlinecut, 0-1 transition, close to normal position only, RCT vs RP, notch=(60,120), rccutoff=100", x1=-1200, y1=-611.5, x2=-1300, y2=-596, rampratex=1000, rampratey=1000, linecut=1, followtolerance=0, notch="60, 120", RCcutoff=100)


	variable scan_duration = 600 //in seconds
	variable scan_width = 60 //mV (RP*0.16)
	variable ramprate = 1000 // ramping back between scans mV/s
	variable delayy = 0.5 // settle time in s before next sweep
	variable sweeprate = 1
	variable num_repeats, startx, finx
	variable centerx, start_center = -1250
	centerx = start_center
//	startx = -1250-scan_width/2
//	finx = -1250+scan_width/2
	setsrsamplitude(srs3, 0)


	rampOutputfdac(fastdac,7, start_center)

	i=0; j=0; k=0
	do // Loop to change k var3
		setls625fieldwait(magy, var3[k])
		timsleep(120)
		do	// Loop for change j var2
//			rampmultiplebd(bd6, "", Var2[j])
			do // Loop for changing i var1 and running scan

//				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]

//				num_repeats = round(scan_duration*sweeprate[i]/scan_width) // Simple version
				num_repeats = round(scan_duration/(scan_width/sweeprate+scan_width/ramprate + delayy)) // Complex version including sweep back and delayy


				if (num_repeats < 2)  // Scanrepeat doesn't like 1D waves I think.
					num_repeats = 2
				endif
//				rampOutputfdac(fastdac,7, -1250)
				rampOutputfdac(fastdac,7, centerx)
				rampOutputfdac(fastdac,4,-4520)
//				centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
				centerx = centerontransitionfd(fastdac, 7, 0, width=100, setchargesensor=1)
				setsrsamplitude(srs1, acbias[i])
				sprintf comment, "magy = %fmT, acbias = %dmV, acbias, transition, entropy, 2drepeat, rccutoff=20, sweeprate=%dmV/s, num_repeats=%d, scan_width = %d", getls625field(magy), acbias[i], sweeprate, num_repeats, scan_width
				print comment + "\r"
//				srs_theta()
				ScanFastDACrepeat(fastdac, centerx-scan_width/2, centerx+scan_width/2, "7", sweeprate, num_repeats, nosave=0, delayy=delayy, ramprate=ramprate, comments=comment,  rccutoff=20)
				timsleep(30) // let temp stablize again after lakeshore has to cycle through to getstatus

				i+=1
			while (i < numpnts(acbias))
//			DCbiasscan(numrows=601, centerx=-1250, RCT=-450, max_bias=200)
//			chargesensoroffsetscan()
//			dcbiasscan(numrows=1001)
			resetls370exclusivereader(ls370)
			timsleep(60)
			setls370exclusivereader(ls370, "ld_mc")

			i=0
			j+=1
		while (j < numpnts(Var2))
//		while (1)  ///////////////////////////////// This makes it run forever!!
		j=0
		k+=1
	while (k< numpnts(Var3))
end


function srs_theta()
	nvar fastdac, bd6, srs1, srs3

	wave/T old_fdacvalstr
	sc_openinstrconnections(0)

	string comment = ""
	variable srs_temp = getsrsamplitude(srs1)
	variable RP
	RP = str2num(old_fdacvalstr[7])
	setsrsamplitude(srs3, 2500)
	setsrsamplitude(srs1, 0)
	centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
	timsleep(2)
	scanfastdacslow(fastdac, RP-10, RP+10, "7", 1000, 0.00001, 1000, comments="measuring theta with lockin, lockin theta")
	rampmultiplefdac(fastdac, "7", RP)
	if (srs_temp != 4)
		setsrsamplitude(srs1, srs_temp)
		centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
		timsleep(2)
		sprintf comment, "srs1out = %dmV, measuring theta with lockin, lockin theta", srs_temp
		scanfastdacslow(fastdac, RP-10, RP+10, "7", 1000, 0.00001, 1000, comments=comment)
		rampmultiplefdac(fastdac, "7", RP)
	endif
	setsrsamplitude(srs1, srs_temp)
	setsrsamplitude(srs3, 0)
end


function DCbiasScan([numrows, centerx, RCT, max_bias])
	variable numrows, centerx, RCT, max_bias

	nvar fastdac, bd6, srs1
	wave fadcattr

	killvisa()
	sc_openinstrconnections(0)  // Make sure connections are open

	variable srs_out = getsrsamplitude(srs1)
	duplicate/o/free fadcattr, temp_fadcattr  // Store to reset later
	fadcattr[][2] = 32  // Turn off reading
	fadcattr[0][2] = 48 // Turn on for CS only
	setsrsamplitude(srs1, 0)

	numrows = paramisdefault(numrows) ? 401 : numrows
	centerx = paramisdefault(centerx) ? -1250 : centerx
	RCT = paramisdefault(RCT) ? -5050 : RCT
	Variable RCSS = -230
	variable RP = centerx

	max_bias = paramisdefault(max_bias) ? 200 : max_bias

	string comment
	sprintf comment, "right side, dcbias, 2drepeat, max_bias = %dmV, notch=(60,120), rccutoff=100, RCT = %dmV, RCSS = %dmV", max_bias, RCT, RCSS

	rampoutputfdac(fastdac, 4, RCT)
	rampoutputfdac(fastdac, 6, RCSS)
	rampoutputfdac(fastdac, 7, RP)
	centerontransitionfd(fastdac, 4, 0, width=200, setchargesensor=1)
	ScanFastDACBabyDac2D(fastdac, bd6, centerx-30, centerx+30, "7", 30, -max_bias, +max_bias, "12", numrows, nosave=0, delayy=0.5, ramprate=1000, y_label="DCbias/mV(10Mohm)", comments=comment, notch="60,120", rccutoff=100)
	rampoutputfdac(fastdac, 7, RP)
	duplicate/o temp_fadcattr, fadcattr //Reset back to previous
	setsrsamplitude(srs1, srs_out)
	rampmultiplebd(bd6, "12", 0) //Turn off DC heat
end


function DCbiasRepeat([sweeprate, numrepeats])
	variable sweeprate, numrepeats
	nvar fastdac, bd6, srs1
	wave fadcattr

	sweeprate = paramisdefault(sweeprate) ? 50 : sweeprate
	numrepeats = paramisdefault(numrepeats) ? 100 : numrepeats

	killvisa()
	sc_openinstrconnections(0)  // Make sure connections are open

	variable srs_out = getsrsamplitude(srs1)
	duplicate/o/free fadcattr, temp_fadcattr  // Store to reset later
	fadcattr[][2] = 32  // Turn off reading
	fadcattr[0][2] = 48 // Turn on for CS only
	setsrsamplitude(srs1, 0)

	variable RCT = -600
	Variable RCSS = -230
	variable RP = -1250
	variable bias = 14.142 //in nA!!!! i.e. 10nA = 100mV DC or 353.5mV on SRS (500/sqrt2 because it shows RMS, 500 because of 50Mohm resistor instead of 10Mohm)


	string comment
	sprintf comment, "right side, dcbias, 2drepeat, notch=(60,120), rccutoff=100, RCT = %dmV, RCSS = %dmV, bias = %fnA, sweeprate = %fmV/s, repeats = %d", RCT, RCSS, bias, sweeprate, numrepeats

	// Get to transition
	rampoutputfdac(fastdac, 4, RCT)
	rampoutputfdac(fastdac, 6, RCSS)
	rampoutputfdac(fastdac, 7, RP)

	// Do scan with DC heat
	centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
	rampmultiplebd(bd6, "12", bias*10) //Turn on DC heat (*10 because of 10Mohm resistor to convert from mV to nA)
	ScanFastDACrepeat(fastdac, -1250-40, -1250+40, "7", sweeprate, numrepeats, nosave=0, delayy=0.5, ramprate=1000, y_label="Repeats", comments=comment, notch="60,120", rccutoff=100)
	rampoutputfdac(fastdac, 7, RP)
	rampmultiplebd(bd6, "12", 0) //Turn off DC heat

	// Now do the same scan without DC or AC heat to make sure theta calibration is correct for fridge temp
	centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
	ScanFastDACrepeat(fastdac, -1250-20, -1250+20, "7", sweeprate, numrepeats, nosave=0, delayy=0.5, ramprate=1000, y_label="Repeats", comments=comment, notch="60,120", rccutoff=100)
	rampoutputfdac(fastdac, 7, RP)

	// Reset
	setsrsamplitude(srs1, srs_out)
	duplicate/o temp_fadcattr, fadcattr //Reset back to previous
end


function chargesensoroffsetscan()
	nvar fastdac, bd6, srs1
	wave fadcattr

	killvisa()
	sc_openinstrconnections(0)  // Make sure connections are open

	variable srs_out = getsrsamplitude(srs1)
	duplicate/o/free fadcattr, temp_fadcattr  // Store to reset later
	fadcattr[][2] = 32  // Turn off reading
	fadcattr[0][2] = 48 // Turn on for CS only
	setsrsamplitude(srs1, 0)

//	variable RCT = -600
//	Variable RCSS = -230
//	variable RP = -1250

	string comment
	sprintf comment, "charge sensor offset, 1D"

//	rampoutputfdac(fastdac, 4, RCT)
//	rampoutputfdac(fastdac, 6, RCSS)
//	rampoutputfdac(fastdac, 7, RP)
	centerontransitionfd(fastdac, 4, 0, width=20, setchargesensor=1)
	rampmultiplebd(bd6, "15", -600)  // Set charge sensor to zero
	ScanFastDAC(fastdac, -1, 0, "1", 1/60, nosave=0, ramprate=1000, y_label="Current/nA", comments=comment)
	rampoutputfdac(fastdac, 1, 0)
	rampmultiplebd(bd6, "15", -1915) // set back to 100uV
	duplicate/o temp_fadcattr, fadcattr //Reset back to previous
	setsrsamplitude(srs1, srs_out)

	rampmultiplebd(bd6, "12", 0) //Turn off DC heat

end



function ScanFastDac2DLine(fd, startx, finx, channelsx, sweeprate, starty, finy, channelsy, numptsy, delayy, width, [comments, x_label, y_label, rampratex, rampratey, x1, y1, x2, y2, linecut, followtolerance, startrange, notch, RCcutoff, numAverage, ignore_positive])//Units: mV
	variable fd, startx, finx, sweeprate, starty, finy, numptsy, delayy, rampratex, rampratey
	variable x1, y1, x2, y2, width, linecut, startrange
	variable followtolerance, ignore_positive, RCcutoff, numAverage
	//startrange = how many mV to look from end of scan range in x for first transition
	// findthreshold = tolerance in findtransition (~1 is high (not very reliable), 5 is low (very reliable))
	string channelsx, x_label, y_label, channelsy, comments, notch

	variable i=0, j=0, setpointx, setpointy, ft = followtolerance, threshold

	svar VKS = $getVKS()  //Global VariableKeyString so it can be passed and altered by the function (e.g. Cut2Dlines)
	VKS = ""  // Reset global string

	startrange = paramIsDefault(startrange) ? 150 : startrange
	rampratex = paramisdefault(rampratex) ? 1000 : rampratex //Max speed by default
	if (startx >= finx)
		abort "Please make start x less than fin x"
	endif


	if(paramisdefault(x1) || paramisdefault(x2) || paramisdefault(y1) || paramisdefault(y2))
		variable sy, numx
		wave ADC0 //uses charge transition to find positions and gradient
		print "Scanning two lines to calculate initial gradient and transition coords"
		numx = round(abs(startx-finx) < 100 ? 100 : abs(startx - finx)) //numx is larger of 100points or every 1mV
//		if (startattop == 1)
//			sy = starty < finy ? finy : starty //sets sy to higher of starty/finy to scan from top down
		if (starty > finy) //If starting from top of scan
//			sy = starty
			rampmultiplefdac(fd, channelsx, startx)
			rampmultiplefdac(fd, channelsy, starty)
			sc_sleep(0.1)
			CorrectChargeSensor(fd=fd, fdchannel=5, fadcchannel=0, i=0, check=0)
			ScanFastDAC(fd, startx, startx+startrange, channelsx, sweeprate, nosave=1)
		else //Starting from bottom
			rampmultiplefdac(fd, channelsx, finx-startrange)
			rampmultiplefdac(fd, channelsy, starty)
			sc_sleep(0.1)
			CorrectChargeSensor(fd=fd, fdchannel=5, fadcchannel=0, i=0, check=0)
			ScanFastDAC(fd, finx-startrange, finx, channelsx, sweeprate, nosave=1)
		endif

		x1 = findtransitionmid(ADC0, threshold=threshold)
		if(numtype(x1) == 2) //if didn't find it there, try other part
			doAlert/T="Didn't find transition" 1, "Do you want to see the rest of the scan region?"
			if(V_flag == 2) //No clicked
				abort "Didn't want to look in rest of range"
			endif
			ScanFastDAC(fd, startx, finx, channelsx, sweeprate, nosave=1)
			Killwindow/z ADC0  //Attempt to not clutter, but not sure if it will have this name each time.
			Display/N=ADC0 ADC0
			abort "Restart Scan with new parameters"
		endif

//		y1 = sy
		y1 = starty
		rampmultiplefdac(fd, channelsy, starty+5, ramprate = 1000)
		ScanFastDAC(fd, x1-startrange/2, x1+startrange/4, channelsx, 100, nosave=1)
		x2 = findtransitionmid(ADC0, threshold=threshold)
		if(numtype(x2) == 2)
			abort "failed to find charge transition at first row +5mV"
		endif
		y2 = starty+5
		print "x1 = " + num2str(x1) + ", " + "y1 = " + num2str(y1) + ", " + "x2 = " + num2str(x2) + ", " + "y2 = " + num2str(y2) //useful if you want to run the same scan multiple times
	endif

	VKS = replacenumberbykey("x1", VKS, x1)
	VKS = replacenumberbykey("x2", VKS, x2)
	VKS = replacenumberbykey("y1", VKS, y1)
	VKS = replacenumberbykey("y2", VKS, y2)
	VKS = replacenumberbykey("w", VKS, width)



//	// y Channels and startpoints.... Required for fdacRecordValues
//	string startys = "", finys = ""
//	for(i=0; i<itemsInList(channelsy, ","); i++)
//		Rampoutputfdac(fd, str2num(stringfromlist(i, channelsy, ",")), starty, ramprate=rampratey)
//		startys = addlistitem(num2str(starty), startys, ",")
//		finys = addlistitem(num2str(finy), finys, ",")
//	endfor
//	startys = startys[0,strlen(startys)-2] // Remove comma at end
//	finys = finys[0,strlen(finys)-2]	 		// Remove comma at end


	if (paramisdefault(x_label))
		x_label = getlabel(channelsx, fastdac=1)
	endif
	if (paramisdefault(y_label))
		y_label = getlabel(channelsy, fastdac=1)
	endif

	variable numptsx
	numptsx = get_numpts_from_sweeprate(fd, -width/2, width/2, sweeprate)

	InitializeWaves(-width/2, width/2, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label= y_label, fastdac=1, linecut=1)
	make/o/n=(ceil(abs(finx-startx)/width*numptsx), numptsy) FullScan //For displaying the full scan, but not saved
	setscale /i x, startx, finx, FullScan
	setscale /i y, starty, finy, FullScan

	if (linecut == 1)
		variable/g sc_is2d = 2
		make/o/n=(numptsy) sc_linestart
		setscale /i x, starty, finy, sc_linestart
	endif
	VKS = replacenumberbykey("x1", VKS, x1)
	VKS = replacenumberbykey("x2", VKS, x2)
	VKS = replacenumberbykey("y1", VKS, y1)
	VKS = replacenumberbykey("y2", VKS, y2)
	VKS = replacenumberbykey("w", VKS, width)
	//VKS = replacenumberbykey("n", VKS, 0) 		//used by Cut2Dline for adapting line


  	// main loop
  	variable/g sc_scanstarttime = datetime
  	variable sx, fx
	do
		setpointy = starty + (i*(finy-starty)/(numptsy-1))
		Cut2Dline(startx = sx, finx = fx, y = setpointy, followtolerance=followtolerance) //Returns startx and finx of scan line in sx and fx
		sc_linestart[i] = sx
//		sx = sx < startx ? startx : sx
//		fx = fx > finx ? finx : fx
//
	  	RampMultiplefdac(fd, channelsy, setpointy, ramprate=rampratey)
		rampmultiplefdac(fd, channelsx, sx, ramprate=rampratex)  // set charge sensor at start of scan line each time to avoid uncertainty of where transition is
		sc_sleep(0.1)
		CorrectChargeSensor(fd = fd, fdchannel = 5, fadcchannel = 0, i=i, check=0)
		rampmultiplefdac(fd, channelsx, sx, ramprate=rampratex)
		sc_sleep(delayy)

		//// Put into strings for fastdac
		string startxs = "", finxs = ""
		for(j=0; j<itemsInList(channelsx, ","); j++)
			Rampoutputfdac(fd, str2num(stringfromlist(j, channelsx, ",")), sx, ramprate=rampratex)
			startxs = addlistitem(num2str(sx), startxs, ",")
			finxs = addlistitem(num2str(fx), finxs, ",")
		endfor
		startxs = startxs[0,strlen(startxs)-2] // Remove comma at end
		finxs = finxs[0,strlen(finxs)-2]	 		// Remove comma at end
		/////////////////////////////

		fdacRecordValues(fd,i,channelsx,startxs,finxs,numptsx,delay=delayy,ramprate=rampratex,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)
			// tell cutfunc another line is completed
		i+=1
		VKS = ReplaceNumberByKey("n", VKS, i) //Tells cut func which row has finished being scanned
	while (i<numptsy)
	savewaves(msg=comments, fastdac=1)
end

function rampmultiplefdac(fd, channels, setpoint, [ramprate, ignore_positive])
	variable fd, setpoint, ramprate, ignore_positive
	string channels
	nvar fd_ramprate
	ramprate = paramisdefault(ramprate) ? fd_ramprate : ramprate
	variable i=0
	for (i=0; i < itemsInList(channels, ","); i++)
		rampoutputfdac(fd, str2num(stringfromlist(i, channels, ",")), setpoint, ramprate=ramprate)
	endfor
end





function Cut2Dline([x, y, followtolerance, startx, finx]) //tests if x, y lie within lines defined in VKS. Returns 1 for Yes, 0 for No, or returns startx and finx of next line scan if used for fastscan
	//followtolerance will adapt line equation up to tolerance (0.1 = 10% change)
	variable x, y, followtolerance
	variable &startx, &finx //For returning start and fin if being used by FastScan2D
	svar VKS = $GetVKS() 	//VariableKeyString (global so it can storechanges)   VKS = "m; HighC; LowC; x1; x2; y1; y2"

	variable m, HighC, LowC, c, ft = followtolerance, n, FS=0  //High/Low for the two y = mx+c equations, FS just to set whether fastscan or not

	if (!paramisdefault(startx) || !paramisdefault(finx)) //If either not default, check all not default
		if (paramisdefault(startx) || paramisdefault(finx) || paramisdefault(y))
			abort "Need startx, finx, and y to return startx and finx"
		else
			FS=1
			wave ADC0, sc_xdata
			if (dimsize(ADC0,0) != numpnts(sc_xdata))
				wave i_sense2d = ADC0_2d //Assumes I_sense data is on FastADC0
			else
				wave i_sense2d = ADC0_2d //Hopefully makes compatible with rest of code
			endif
		endif
	elseif (!paramisdefault(x) || !paramisdefault(y))
		if (paramisdefault(x) || paramisdefault(y))
			abort "Need x and y to return whether in cut line or not"
		endif
	else
		abort "Something horribly wrong, need more inputs"
	endif


	m = numberbykey("m", VKS)
	HighC = numberbykey("HighC", VKS)
	LowC = numberbykey("LowC", VKS)
	c = numberbykey("c", VKS) //Used for FastScan
	n = numberbykey("n", VKS) //Used for followfunction

	//caluclates Line equation from coords or previous data lines if necessary
	if (numtype(m)!=0 || numtype(HighC)!=0 || numtype(LowC)!=0 || n >= 2)  //Calculating line equations if necessary
		variable x1, x2, y1, y2, w //for calculating y = mx + c equations

		w = numberbykey("w", VKS)
		if(n == 0 || numtype(n) == 2) //For first time or if n is not set and defaults to NaN
			x1 = numberbykey("x1", VKS)
			x2 = numberbykey("x2", VKS)
			y1 = numberbykey("y1", VKS)
			y2 = numberbykey("y2", VKS)
		elseif(ft == 0 && n >= 2) //If no finite tolerance
			n = -2 			//will stop Cut2Dline from storing junk data into VKS
			VKS = replacenumberbykey("n", VKS, -1) //when n = -1 is loaded next time it won't try calculate new eq
		elseif(n >= 2 && ft!= 0) //enough rows to calculate new coords and finite tolerance
			wave w_coef, sc_ydata, sc_linestart	//Fits to charge transition from charge sensor, funcfit stores values in W_coef, sc_ywave has y values of data, sc_linestart has first x position of isense_2d data
			nvar sc_is2d
			variable i = 0, nend

			if(n < (ceil(abs(10/dimdelta(sc_ydata,0)))) && abs(dimdelta(sc_ydata,0)) < 5) //If there isn't enough data to do 10mV in y direction use all gathered so far
				nend = n
			elseif (abs(dimdelta(sc_ydata,0))<5) //otherwise use enough data to cover 10mV
				nend = ceil(abs(10/dimdelta(sc_ydata,0)))
			else
				nend = 2 // if ydata is sparse (i.e. quick scan) just use previous two points for gradient
			endif

			make/Free/O/N=(nend,2) coords = NaN	 //to store multiple transition coords
			do //Find previous x and y coords of transitions
				duplicate/FREE/O/RMD=[][(n-1)-i] i_sense2d datrow
				if(sc_is2d == 2) //only necessary for line cut
					setscale/P x, sc_linestart[(n-1)-i], dimdelta(i_sense2d, 0), datrow //Need to give correct dimensions before fitting
				endif
				coords[i][0] = fitcharge1d(datrow)
				coords[i][1] = sc_ydata[(n-1)-i]
				i+=1
			while (i<nend)

			wavestats/Q/M=1/RMD=[][0] coords
			if(V_numnans/dimsize(coords,0) < 0.5 && dimsize(coords,0) - V_numNans >= 2) //if at least 50% successful fits	and at least two data points make and check new m and Cs
				curveFit/Q line, coords[][1] /X=coords[][0]
				m = w_coef[1] 						//new gradient from linefit

				variable oldm, TE // TE for ToleranceExceedNum number that I store in VKS
				oldm = numberbykey("m", VKS)
				TE = numberbykey("TolExceedNum", VKS) //Loads previous error code stored (NaN by default)
				if(numtype(TE) == 2) //Sets TE to zero if first time being loaded
					TE = 0
				elseif(TE > 0.4)
					TE = TE-0.4 		//so that E only causes abort if maxes out 5 times in a row, or more than ~40% of the time
				endif
				// Check to see if m has changed more than allowed by tolerance (Probably won't handle stationary points)
				if(abs((m-oldm)/oldm) > ft)
					print "m change by " +num2str(((m-oldm)/oldm)*100) + "% @ n = " + num2str(n) + ", TE @ " + num2str(TE+1)
					m = oldm*(1+sign(abs(m)-abs(oldm))*ft) //increases/decreases m by max allowed amount
					TE += 1 //increment Error value
				endif
				if(TE>4)
					savewaves()
					abort "Cut2Dline has changed gradient by max tolerance too many times in a row"
				endif
				VKS = replacenumberbykey("TolExceedNum", VKS, TE) //Stores total errors
				VKS = replacenumberbykey("n", VKS, -1) //Prevent re-running this whole chunk of code until a new n value is stored by scan function
				i = 0
				do //get most recent nonNan transition coord
					x1 = coords[i][0]; y1 = coords[i][1]
					i+=1
				while(numtype(x1)==2 && i<nend)
				if(numtype(x1) == 0) //If good coord then calc high and low C
					HighC = y1-m*(x1-sign(m)*w/2) 	//
					LowC = y1-m*(x1+sign(m)*w/2)		//
					c = y1-m*x1
				else
					if (FS == 1)
						savewaves(fastdac=1, msg="aborted")
						abort "Did not manage to make new gradient, waves not saved!!"
					else
						savewaves(fastdac=1, msg="aborted")
						abort "Can't find x1, y1 to calc new C values. Waves not saved!!"
					endif
				endif

			else
				VKS = replacenumberbykey("n", VKS, -1) //don't calc again until new row of data
				n=-2	//don't store junk data in VKS
			endif
		else
			abort "Cut2Dline Failed unexpectedly, waves not saved!!"
		endif


		if(n == 0 || numtype(n) == 2) //if first time through or not using n
			m = ((y2-y1)/(x2-x1))
			HighC = y1-m*(x1-sign(m)*w/2) //sign(m) makes it work for +ve or -ve gradient
			LowC = y1-m*(x1+sign(m)*w/2)	//For both y = mx + c equations
			c = y1-m*x1
		endif


		//If sanity checks passed/values made acceptable, or just first time through then store values
		if(n != -2 ) //use this to prevent storing values
			VKS = replacenumberbykey("m", VKS, m)				//stores line eq back in VKS
			VKS = replacenumberbykey("HighC", VKS, HighC)
			VKS = replacenumberbykey("LowC", VKS, LowC)
			VKS = replacenumberbykey("c", VKS, c)
			VKS = replacenumberbykey("n", VKS, -1) //prevent recalculating until new data row
		endif
	endif

	w = numberbykey("w", VKS)
	//Part that actually checks if x, y coords should be measured, or returns startx and finx for fastscan
	if (FS == 1)
		startx = (y-c)/m - w/2
		finx = (y-c)/m + w/2
	else
		if ((y - m*x - LowC) > 0 && (y - m*x - HighC) < 0)
			return 1
		else
			return 0
		endif
	endif

end

function gate_sweep_only([duration])
	variable duration
	nvar bd6, fastdac, srs1
	svar ls370

	nvar bd_ramprate
	nvar fd_ramprate
	variable bd_ramprate_before = bd_ramprate
	variable fd_ramprate_before = fd_ramprate

	variable i = 0
	variable srs = getsrsamplitude(srs1)

	wave/t old_dacvalstr
	wave/t old_fdacvalstr
	variable RCB = str2num(old_dacvalstr[6])
	variable HQPCBias = str2num(old_dacvalstr[12])
	variable CA0 = str2num(old_dacvalstr[15])

	variable LCT = str2num(old_fdacvalstr[0])
	variable LCB = str2num(old_fdacvalstr[2])
	variable RCT = str2num(old_fdacvalstr[4])
	variable RCSQ = str2num(old_fdacvalstr[5])
	variable RCSS = str2num(old_fdacvalstr[6])
	variable RP = str2num(old_fdacvalstr[7])

	variable wait_time = 2.5
	duration = paramisdefault(duration) ? 120 : duration


	setsrsamplitude(srs1, 0)
	rampmultiplebd(bd6, "15", -600)
	rampmultiplebd(bd6, "12", 0)

	bd_ramprate = 500
	fd_ramprate = 500

	variable numrepeats = round(duration/(2*wait_time+6000/bd_ramprate))
	if (numrepeats < 2)
		numrepeats = 2
	endif


	printf "Starting %d sweeps for total of %d seconds of sweeping dacs back and forth between -200 and -800 mV", numrepeats, duration
	for (i = 0; i < numrepeats; i++)
		rampmultiplefdac(fastdac, "0, 2, 4, 5, 6", -200)
		rampmultiplefdac(fastdac, "7", -500)
		rampmultiplebd(bd6, "6", -200)
		timsleep(wait_time)
		rampmultiplefdac(fastdac, "0, 2, 4, 5, 6", -800)
		rampmultiplebd(bd6, "6", -800)
		rampmultiplefdac(fastdac, "7", -2700)
		timsleep(wait_time)
	endfor
	print "Finished ramping back and forth"
	rampmultiplefdac(fastdac, "0", LCT)
	rampmultiplefdac(fastdac, "2", LCB)
	rampmultiplefdac(fastdac, "4", RCT)
	rampmultiplefdac(fastdac, "5", RCSQ)
	rampmultiplefdac(fastdac, "6", RCSS)
	rampmultiplefdac(fastdac, "7", RP)
	rampmultiplebd(bd6, "6", RCB)
	rampmultiplebd(bd6, "12", HQPCbias)

	bd_ramprate = bd_ramprate_before
	fd_ramprate = fd_ramprate_before

	rampmultiplebd(bd6, "15", CA0)
	setsrsamplitude(srs1, srs)
end

function gate_sweep_repeat()
	nvar bd6, fastdac, srs1
	svar ls370

	nvar bd_ramprate
	bd_ramprate = 200
	nvar fd_ramprate
	fd_ramprate = 200
	variable i = 0

	variable srs = getsrsamplitude(srs1)
	resetls370exclusivereader(ls370)
	setsrsamplitude(srs1, 0)
	rampmultiplebd(bd6, "15", -580)
	print "Starting 1 hours of sweeping dacs back and forth between -200 and -800 mV"
	for (i = 0; i < 30; i++)
		rampmultiplefdac(fastdac, "0, 2, 4, 5, 6", -200)
		rampmultiplefdac(fastdac, "7", -500)
		rampmultiplebd(bd6, "6", -800)
		timsleep(60)
		rampmultiplefdac(fastdac, "0, 2, 4, 5, 6", -800)
		rampmultiplebd(bd6, "6", -800)
		rampmultiplefdac(fastdac, "7", -2700)
		timsleep(60)
	endfor
	print "Finished ramping back and forth"
	rampmultiplefdac(fastdac, "0, 2", -515)
	rampmultiplefdac(fastdac, "4", -603)
	rampmultiplefdac(fastdac, "5", -471)
	rampmultiplefdac(fastdac, "6", -230)
	rampmultiplefdac(fastdac, "7", -1290)
	rampmultiplebd(bd6, "6", -400)
	rampmultiplebd(bd6, "15", -1895)

	print "Finished ramping back and forth"
	timsleep(1200)
	print "starting scans"
	bd_ramprate = 1000
	fd_ramprate = 1000
	setsrsamplitude(srs1, srs)

	setls370exclusivereader(ls370, "ld_mc")
end

function ramp_repeats_scans()
	variable i=0

	do
		gate_sweep_repeat()
		print "Starting not forever sweeps"
		scan_entropy_forever()
	while (1)
end


function setup_standard_entropy()
	svar ls370
	nvar srs1, bd6, fastdac, srs3

	// Turn on record entropy and charge sensor
	wave fadcattr
	fadcattr[0][2] = 48  // Turn on CS
	fadcattr[1][2] = 48  // Turn on entx
	fadcattr[2][2] = 48  // Turn on enty


	setls370exclusivereader(ls370, "ld_mc")

	//Set srss
	setsrsamplitude(srs1, 1000)
	setsrsfrequency(srs1, 51.1)
	setsrstimeconst(srs1, 0.1)
	setsrsharmonic(srs1, 4)

	setsrstimeconst(srs3, 0.1)
	setsrsharmonic(srs3, 2)


	//Turn off HQPC bias
	rampmultiplebd(bd6, "12", 0) // zero HQPC bias


end


function Step_field_scan()
	nvar fastdac, bd6, magy, srs1
	svar ls370
	string comment
	variable i, j, k
//	make/o/free Var1 = {}
	make/o/free Var2 = {-550, -590}  //HQPC gates
	make/o/free Var2a = {400, 200}   //Max bias in DCbias scans
	make/o/free Var2b = {1000, 600}   //ACbias in entropy scans

	make/o/free Var3 = {200, 100, 50, -50, -100, -200}

	//Setup
	wave fadcattr
	fadcattr[0][2] = 48  // Turn on CS
	fadcattr[1][2] = 48  // Turn on entx
	fadcattr[2][2] = 48  // Turn on enty
	setls370exclusivereader(ls370, "ld_mc")
	setsrsamplitude(srs1, 600)
	setsrsfrequency(srs1, 51.1)
	rampmultiplebd(bd6, "12", 0) // zero HQPC bias
	variable centerx = -1250  // Center of scan


	i=0; j=0; k=0
	do // Loop to change k var3
		setLS625fieldWait(magy, var3[k])
		timsleep(60)
		do	// Loop for change j var2
			rampmultiplefdac(fastdac, "0, 2", Var2[j])  //Ramp HQPC gates
//			do // Loop for changing i var1 and running scan
				printf "Magnet is reporting %fmT\r", getls625field(magy)
				sprintf comment, "Entropy vs field, magy=%dmT, HQPC=%dmV, SRSbias= %dmV, transition, entropy, notch=(17.4, 42.16, 51, 60), rccutoff=40", var3[k], var2[j], var2b[j]
				rampmultiplefdac(fastdac, "7", centerx)
				centerontransitionfd(fastdac, 4, 0, width=40, setchargesensor=1)
				Dcbiasscan(numrows=601, centerx=-1250, RCT=-454, max_bias=var2a[j])
				setsrsamplitude(srs1, var2b[j])
				ScanFastDACrepeat(fastdac, centerx-40, centerx+40, "7", 1, 30, delayy=0.3, nosave=0, comments=comment, rccutoff=40, notch="17.4, 42.16, 51, 60")

//				i+=1
//			while (i < numpnts(Var1))
//			i=0
			j+=1
		while (j < numpnts(Var2))
		j=0
		k+=1
	while (k< numpnts(Var3))
//	notify("Finished all scans") // Currently not working
end


function scan_transition_varying_speed_width()
	nvar fastdac, bd6, srs1, magy
	string comment
	variable i, j, k
	make/o/free Var1 = {30, 10, 1}
	make/o/free var1a = {70, 40, 10}
	make/o/free Var2 = {0, 0, 0} //just repeat 3 times
	make/o/free Var3 = {0}


	variable centerx = -1250
	setsrsamplitude(srs1, 0)

	timsleep(300)
	i=0; j=0; k=0
	do // Loop to change k var3
		do	// Loop for change j var2
			do // Loop for changing i var1 and running scan
				rampmultiplebd(bd6, "", Var1[i])
				sprintf comment, "Transition scans varying speed and width, width=%dmV, speed=%dmV/s transition, notch=(17.4, 42.16, 51, 60), rccutoff=40", var1a[i], var1[i]
				rampmultiplefdac(fastdac, "7", centerx)
				centerontransitionfd(fastdac, 4, 0, width=30, setchargesensor=1)
				ScanFastDACrepeat(fastdac, centerx-var1a[i]/2, centerx+var1a[i]/2, "7", var1[i], 30, delayy=0.3, nosave=0, comments=comment, rccutoff=40, notch="17.4, 42.16, 51, 60")
				i+=1
			while (i < numpnts(Var1))
			i=0
			j+=1
		while (j < numpnts(Var2))
		j=0
		k+=1
	while (k< numpnts(Var3))
	print "Finished all scans"
end


function scan_transition_varying_charge_sensor_bias()
	nvar fastdac, bd6, srs1, magy
	string comment
	variable i, j, k
	make/o/free Var1 = {200, 100, 50}
	make/o/free Var2 = {0}
	make/o/free Var3 = {0}


	variable centerx = -1250
	variable width = 40
	setsrsamplitude(srs1, 600)

	i=0; j=0; k=0
	do // Loop to change k var3
		do	// Loop for change j var2
			do // Loop for changing i var1 and running scan
				sprintf comment, "CSbias = %dmV, entropy scans testing if charge sensor bias has effect, entropy, transition, notch=(17.4, 42.16, 51, 60), rccutoff=40", var1[i]
				rampmultiplefdac(fastdac, "7", centerx)
				rampmultiplebd(bd6, "15", -600-13.15*var1[i])
				centerontransitionfd(fastdac, 4, 0, width=30, setchargesensor=1, natarget=var1[i]/100*3)
				ScanFastDACrepeat(fastdac, centerx-width/2, centerx+width/2, "7", 1, 5, delayy=0.3, nosave=0, comments=comment, rccutoff=40, notch="17.4, 42.16, 51, 60")
				i+=1
			while (i < numpnts(Var1))
			i=0
			j+=1
		while (j < numpnts(Var2))
		j=0
		k+=1
	while (k< numpnts(Var3))
	print "Finished all scans"
end




function Scan_along_transition_repeat()
	nvar fastdac, bd6, srs1
	svar ls370
	string buffer, comment
	variable i, j, k
	make/o/free var2 = {0}
	make/o/free var3 = {0}
	make/o/free var1 = {1}
	killvisa()
	sc_openinstrconnections(0)
	setls370exclusivereader(ls370, "ld_mc")
//	ScanFastDac2DLine(fastdac, -1350, -1150, "7", 1, -620, -590, "4", 31, 0.5, 50, comments="2dlinecut, 0-1 transition, close to normal position only, RCT vs RP, notch=(60,120), rccutoff=100", x1=-1200, y1=-611.5, x2=-1300, y2=-596, rampratex=1000, rampratey=1000, linecut=1, followtolerance=0, notch="60, 120", RCcutoff=100)

	variable delayy = 0.5 // settle time in s before next sweep
	variable srsout = 700
	variable x1=-1418.3, y1=-4220, x2=-1175.6, y2=-4640
	variable width = 40
	variable sweeprate = 1

	//Setup
	wave fadcattr
	fadcattr[0][2] = 48  // Turn on CS
	fadcattr[1][2] = 48  // Turn on entx
	fadcattr[2][2] = 48  // Turn on enty
	i=0; j=0; k=0
//	do // Loop to change k var3
//		rampmultiplebd(bd6, "", Var3[k])
//		do	// Loop for change j var2
//			rampmultiplebd(bd6, "", Var2[j])
			do // Loop for changing i var1 and running scan
				rampOutputfdac(fastdac,7,-1000)
				rampOutputfdac(fastdac,4,-4400)
				setsrsamplitude(srs1, srsout)
//				timsleep(60)  // Time for device to settle after ramping back to beginning
				sprintf comment, "scan along transition with RCT/10 divider, transition, entropy, 2dlinecut, through (x1=%f, y1=%f, x2= %f, y2=%f), rccutoff=100,  notch=(17.4, 42.16, 51, 60), sweeprate=%dmV/s, scan_width = %d", x1, y1, x2, y2, sweeprate, width
				print ""
				ScanFastDac2DLine(fastdac, -1250-600, -1250+600, "7", sweeprate, -4520-200, -4520+200, "4", 21, delayy, width, comments=comment, x1=x1, y1=y1, x2=x2, y2=y2, rampratex=1000, rampratey=1000, linecut=1, followtolerance=0, notch="17.4, 42.16, 51, 60", rccutoff=50)
				i+=1
			while (i < 5)
			timsleep(30) // let temp stablize again after lakeshore has to cycle through to getstatus
//			DCbiasScan(numrows=201)
//			chargesensoroffsetscan()
//			resetls370exclusivereader(ls370)
//			timsleep(60)
//			setls370exclusivereader(ls370, "ld_mc")
//
//			i=0
//			j+=1
//		while (j < numpnts(Var2))
//		while (1)  ///////////////////////////////// This makes it run forever!!
//		j=0
//		k+=1
//	while (k< numpnts(Var3))
end



function scan_fourth_harmonic_vs_bias()
	nvar fastdac, bd6, srs1, magy, srs3
	string comment
	variable i, j, k
	make/o/free Var1 = {100, 200, 300, 400, 500, 750, 1000, 1500}

	variable centerx = -1250
	variable width = 40

	//Setup
	setsrstimeconst(srs1, 0.3)
	setsrsharmonic(srs1, 4)
	setsrstimeconst(srs3, 0.3)



	i=0; j=0; k=0
	do // Loop for changing i var1 and running scan
		sprintf comment, "measuring 4th harmonic, slow measurement, srs1=%dmV", var1[i]
		rampmultiplefdac(fastdac, "7", centerx)
		setsrsamplitude(srs1, var1[i])
		centerontransitionfd(fastdac, 4, 0, width=200, setchargesensor=1)
		scanfastdacslow(fastdac, -1250-20, -1250+20, "7", 601, 0.00001, 1000, nosave=0, comments=comment)
		i+=1
	while (i < numpnts(Var1))
	print "Finished all scans"

	//reset
	setsrstimeconst(srs1, 0.03)
	setsrstimeconst(srs3, 0.03)


end


function temp_loop()
	svar ls370

	make/o/t channels = {"ld_mc", "ld_still", "ld_mc", "ld_4k","ld_mc", "ld_still"}
	variable i = 0
	do
		do
			setls370exclusivereader(ls370, channels[i])
			timsleep(15)
			i+=1
		while (i< numpnts(channels))
		i=0
	while (1)
end




function createHugeDataSet(numpts)
	variable numpts
	// create 2d wave to hold data
	make/o/n=(numpts,numpts) data = enoise(1)
	//display
	//appendimage data
	saveDataSet(data)
end
function saveDataSet(data)
	wave data
	newpath/c/o/q savepath "C:Users:FolkLab:Desktop:SaveFolder:"
	// create HDF5 container
	variable/g hdf5_id=0
	string filename = "file_"+num2istr(unixtime())+".h5"
	HDF5CreateFile/z/p=savepath hdf5_id as filename
	if(v_flag != 0)
		print "HDF5 create falied!"
		abort
	endif
	// save data set to container
	HDF5SaveData/z/igor=-1/tran=1/writ=1 data, hdf5_id
	if(v_flag != 0)
		print "HDF5 save falied!"
		abort
	endif
	// close HDF5 container
	HDF5CloseFile hdf5_id
	if(v_flag != 0)
		print "HDF5 clsse falied!"
		abort
	else
		string mes = ""
		sprintf mes, "saving file %s to disk", filename
	endif
	copyDataSet(filename)
end
function copyDataSet(filename)
	string filename
	copyfile/z=1/d/p=savepath filename as ":CopyFolder"
end
