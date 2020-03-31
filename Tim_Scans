////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Scans /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAScans()
end


function ReadVsTime(delay, [comments]) // Units: s
	variable delay
	string comments
	variable i=0

	if (paramisdefault(comments))
		comments=""
	endif

	InitializeWaves(0, 1, 1, x_label="time (s)")
	nvar sc_scanstarttime // Global variable set when InitializeWaves is called
	do
		sc_sleep(delay)
		RecordValues(i, 0,readvstime=1)
		i+=1
	while (1)
	SaveWaves(msg=comments)
end


function ScanBabyDAC(instrID, start, fin, channels, numpts, delay, ramprate, [comments, nosave]) //Units: mV
	// sweep one or more babyDAC channels
	// channels should be a comma-separated string ex: "0, 4, 5"
	variable instrID, start, fin, numpts, delay, ramprate, nosave
	string channels, comments
	string x_label
	variable i=0, j=0, setpoint

	if(paramisdefault(comments))
	comments=""
	endif

	x_label = GetLabel(channels)

	// set starting values
	setpoint = start
	RampMultipleBD(instrID, channels, setpoint, ramprate=ramprate)

	sc_sleep(1.0)
	InitializeWaves(start, fin, numpts, x_label=x_label)
	do
		setpoint = start + (i*(fin-start)/(numpts-1))
		RampMultipleBD(instrID, channels, setpoint, ramprate=ramprate)
		sc_sleep(delay)
		RecordValues(i, 0)
		i+=1
	while (i<numpts)
	if (nosave == 0)
  		SaveWaves(msg=comments)
  	else
  		dowindow /k SweepControl
	endif
end


function ScanBabyDAC2D(instrID, startx, finx, channelsx, numptsx, delayx, rampratex, starty, finy, channelsy, numptsy, delayy, rampratey, [comments, eta]) //Units: mV
  variable instrID, startx, finx, numptsx, delayx, rampratex, starty, finy, numptsy, delayy, rampratey, eta
  string channelsx, channelsy, comments
  variable i=0, j=0, setpointx, setpointy
  string x_label, y_label

  if(paramisdefault(comments))
    comments=""
  endif

	if (eta==1)
		Eta = (delayx+0.08)*numptsx*numptsy+delayy*numptsy+numptsy*abs(finx-startx)/(rampratex/3)  //0.06 for time to measure from lockins etc, Ramprate/3 because it is wrong otherwise
		Print "Estimated time for scan = " + num2str(eta/60) + "mins, ETA = " + secs2time(datetime+eta, 0)
	endif
  x_label = GetLabel(channelsx)
  y_label = GetLabel(channelsy)

  // set starting values
  setpointx = startx
  setpointy = starty
  RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
  RampMultipleBD(instrID, channelsy, setpointy, ramprate=rampratey)

  // initialize waves
  InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

  // main loop
  do
    setpointx = startx
    setpointy = starty + (i*(finy-starty)/(numptsy-1))
    RampMultipleBD(instrID, channelsy, setpointy, ramprate=rampratey)
    RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
    sc_sleep(delayy)
    j=0
    do
      setpointx = startx + (j*(finx-startx)/(numptsx-1))
      RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
      sc_sleep(delayx)
      RecordValues(i, j)
      j+=1
    while (j<numptsx)
    i+=1
  while (i<numptsy)
  SaveWaves(msg=comments)
end


function ScanBabyDACRepeat(instrID, startx, finx, channelsx, numptsx, delayx, rampratex, numptsy, delayy, [offsetx, comments]) //Units: mV, mT
	// x-axis is the dac sweep
	// y-axis is an index
	// this will sweep: start -> fin, fin -> start, start -> fin, ....
	// each sweep (whether up or down) will count as 1 y-index

	variable instrID, startx, finx, numptsx, delayx, rampratex, numptsy, delayy, offsetx
	string channelsx, comments
	variable i=0, j=0, setpointx, setpointy
	string x_label, y_label

	if(paramisdefault(comments))
		comments=""
	endif

	if( ParamIsDefault(offsetx))
		offsetx=0
	endif

	// setup labels
	x_label = GetLabel(channelsx)
	y_label = "Sweep Num"

	// intialize waves
	variable starty = 0, finy = numptsy-1, scandirection=0
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

	// set starting values
	setpointx = startx-offsetx
	RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
	sc_sleep(2.0)

	do
		if(mod(i,2)==0)
			j=0
			scandirection=1
		else
			j=numptsx-1
			scandirection=-1
		endif

		setpointx = startx - offsetx + (j*(finx-startx)/(numptsx-1)) // reset start point
		RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
		sc_sleep(delayy) // wait at start point
		do
			setpointx = startx - offsetx + (j*(finx-startx)/(numptsx-1))
			RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
			sc_sleep(delayx)
			RecordValues(i, j)
			j+=scandirection
		while (j>-1 && j<numptsx)
		i+=1
	while (i<numptsy)
	SaveWaves(msg=comments)
end


function ScanBabyDACUntil(instrID, start, fin, channels, numpts, delay, ramprate, checkwave, value, [operator, comments, scansave]) //Units: mV
  // sweep one or more babyDAC channels until checkwave < (or >) value
  // channels should be a comma-separated string ex: "0, 4, 5"
  // operator is "<" or ">", meaning end on "checkwave[i] < value" or "checkwave[i] > value"
  variable instrID, start, fin, numpts, delay, ramprate, value, scansave
  string channels, operator, checkwave, comments
  string x_label
  variable i=0, j=0, setpoint

  if(paramisdefault(comments))
    comments=""
  endif

  if(paramisdefault(operator))
    operator = "<"
  endif

  if(paramisdefault(scansave))
    scansave=1
  endif

  variable a = 0
  if ( stringmatch(operator, "<")==1 )
    a = 1
  elseif ( stringmatch(operator, ">")==1 )
    a = -1
  else
    abort "Choose a valid operator (<, >)"
  endif

  x_label = GetLabel(channels)

  // set starting values
  setpoint = start
  RampMultipleBD(instrID, channels, setpoint, ramprate=ramprate)

  InitializeWaves(start, fin, numpts, x_label=x_label)
  sc_sleep(1.0)

  wave w = $checkwave
  wave resist
  do
    setpoint = start + (i*(fin-start)/(numpts-1))
    RampMultipleBD(instrID, channels, setpoint, ramprate=ramprate)
    sc_sleep(delay)
    RecordValues(i, 0)
    if (a*(w[i] - value) < 0 )
			break
    endif
    i+=1
  while (i<numpts)

  if(scansave==1)
    SaveWaves(msg=comments)
  endif
end


function ScanBabyDAC_SRS(babydacID, srsID, startx, finx, channelsx, numptsx, delayx, rampratex, starty, finy, numptsy, delayy, [comments]) //Units: mV, mV
	// Example of how to make new babyDAC scan stepping a different instrument (here SRS)
  variable babydacID, srsID, startx, finx, numptsx, delayx, rampratex, starty, finy, numptsy, delayy
  string channelsx, comments
  variable i=0, j=0, setpointx, setpointy
  string x_label, y_label

  if(paramisdefault(comments))
    comments=""
  endif

  sprintf x_label, "BD %s (mV)", channelsx
  sprintf y_label, "SRS%d (mV)", getAddressGPIB(srsID)

  // set starting values
  setpointx = startx
  setpointy = starty
  RampMultipleBD(babydacID, channelsx, setpointx, ramprate=rampratex)
  SetSRSAmplitude(srsID,setpointy)

  // initialize waves
  InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

  // main loop
  do
    setpointx = startx
    setpointy = starty + (i*(finy-starty)/(numptsy-1))
    RampMultipleBD(babydacID, channelsx, setpointx, ramprate=rampratex)
    SetSRSAmplitude(srsID,setpointy)
    sc_sleep(delayy)
    j=0
    do
      setpointx = startx + (j*(finx-startx)/(numptsx-1))
      RampMultipleBD(babydacID, channelsx, setpointx, ramprate=rampratex)
      sc_sleep(delayx)
      RecordValues(i, j)
      j+=1
    while (j<numptsx)
    i+=1
  while (i<numptsy)
  SaveWaves(msg=comments)
end


function ScanFastDAC(instrID, start, fin, channels, [numpts, sweeprate, ramprate, delay, y_label, comments, RCcutoff, numAverage, notch, nosave]) //Units: mV
	// sweep one or more FastDac channels from start to fin using either numpnts or sweeprate /mV/s
	// Note: ramprate is for ramping to beginning of scan ONLY
	// Note: Delay is the wait after rampint to start position ONLY
	// channels should be a comma-separated string ex: "0,4,5"
	variable instrID, start, fin, numpts, sweeprate, ramprate, delay, RCcutoff, numAverage, nosave
	string channels, comments, notch, y_label
	string x_label
	variable i=0, j=0

	// Chose which input to use for numpts of scan
	if (ParamIsDefault(numpts) && ParamIsDefault(sweeprate))
		abort "ERROR[ScanFastDac]: User must provide either numpts OR sweeprate for scan [neither provided]"
	elseif (!ParamIsDefault(numpts) && !ParamIsDefault(sweeprate))
		abort "ERROR[ScanFastDac]: User must provide either numpts OR sweeprate for scan [both provided]"
	elseif (!ParamIsDefault(numpts)) // If numpts provided, just use that
		numpts = numpts
	elseif (!ParamIsDefault(sweeprate)) // If sweeprate provided calculate numpts required
		numpts = get_numpts_from_sweeprate(instrID, start, fin, sweeprate)
	endif

	// Reconnect instruments
	sc_openinstrconnections(0)

	// Set defaults
	nvar fd_ramprate
	ramprate = paramisdefault(ramprate) ? fd_ramprate : ramprate
	delay = ParamIsDefault(delay) ? 0.5 : delay
	if (paramisdefault(notch))
		notch = ""
	endif
	if (paramisdefault(comments))
		comments = ""
	endif

	// Ramp to startx and format inputs for fdacRecordValues
	string starts = "", fins = ""
	RampMultipleFD(instrID, channels, start)
	fd_format_setpoints(start, fin, channels, starts, fins)

	// Let gates settle
	sc_sleep(delay)

	// Get labels for waves
	x_label = GetLabel(channels, fastdac=1)
	if (paramisdefault(y_label))
		y_label = ""
	endif

	// Make waves
	InitializeWaves(start, fin, numpts, x_label=x_label, y_label=y_label, fastdac=1)

	// Do 1D scan (rownum set to 0)
	fdacRecordValues(instrID,0,channels,starts,fins,numpts,ramprate=ramprate,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)

	// Save by default
	if (nosave == 0)
  		SaveWaves(msg=comments, fastdac=1)
  	else
  		dowindow /k SweepControl
	endif
end


function ScanFastDAC2D(fdID, startx, finx, channelsx, starty, finy, channelsy, numptsy, [numptsx, sweeprate, bdID, rampratex, rampratey, delayy, comments, RCcutoff, numAverage, notch, nosave]) //Units: mV
	// 2D Scan for FastDAC only OR FastDAC on fast axis and BabyDAC on slow axis
	// Note: Must provide numptsx OR sweeprate in optional parameters instead
	// Note: To ramp with babyDAC on slow axis provide the BabyDAC variable in bdID
	// Note: channels should be a comma-separated string ex: "0,4,5"
	variable fdID, startx, finx, sweeprate, starty, finy, numptsy, bdID, rampratex, rampratey, delayy, ignore_positive, RCcutoff, numAverage, nosave
	string channelsx, channelsy, comments, notch
	variable i=0, j=0

	// Chose which input to use for numpts of scan
	if (ParamIsDefault(numpts) && ParamIsDefault(sweeprate))
		abort "ERROR[ScanFastDac]: User must provide either numpts OR sweeprate for scan [neither provided]"
	elseif (!ParamIsDefault(numpts) && !ParamIsDefault(sweeprate))
		abort "ERROR[ScanFastDac]: User must provide either numpts OR sweeprate for scan [both provided]"
	elseif (!ParamIsDefault(numpts)) // If numpts provided, just use that
		numpts = numpts
	elseif (!ParamIsDefault(sweeprate)) // If sweeprate provided calculate numpts required
		numpts = get_numpts_from_sweeprate(fdID, start, fin, sweeprate)
	endif

	// Reconnect instruments
	sc_openinstrconnections(0)

	// Set defaults
	nvar fd_ramprate
	rampratex = paramisdefault(rampratex) ? fd_ramprate : rampratex
	rampratey = ParamIsDefault(rampratey) ? fd_ramprate : rampratey
	delay = ParamIsDefault(delay) ? 0.5 : delay
	if (paramisdefault(notch))
		notch = ""
	endif
	if (paramisdefault(comments))
		comments = ""
	endif

	// Ramp to startx and format inputs for fdacRecordValues
	string startxs = "", finxs = ""
	RampMultipleFD(instrID, channelsx, startx)
	fd_format_setpoints(startx, finx, channelsx, startxs, finxs)

	if (ParamIsDefault(bdID)) // If using FastDAC on slow axis
		string startys = "", finys = ""
		RampMultipleFD(instrID, channelsy, starty)
		fd_format_setpoints(starty, finy, channelsy, startys, finys)
	elseif (!ParamIsDefault(bdID)) // If using BabyDAC on slow axis
		RampMultipleBD(bdID, channelsy, starty, ramprate=ramprate)
	endif

	// Let gates settle
	sc_sleep(delayy)

	// Get Labels for waves
	x_label = GetLabel(channelsx, fastdac=1)
	if (ParamIsDefault(bdID)) // If using FastDAC on slow axis
		y_label = GetLabel(channelsy, fastdac=1)
	elseif (!ParamIsDefault(bdID)) // If using BabyDAC on slow axislabels
		y_label = GetLabel(channelsy, fastdac=0)
	endif

	// Make waves
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label= y_label, fastdac=1)

	// Main measurement loop
	variable setpointy, channely
	for(i=0; i<numptsy; i++)
		// Ramp slow axis
		setpointy = starty + (i*(finy-starty)/(numptsy-1))
		if (ParamIsDefault(bdID)) // If using FastDAC on slow axis
			RampMultipleFD(fdID, channelsy, setpointy, ramprate=ramprate)
		elseif (!ParamIsDefault(bdID)) // If using BabyDAC on slow axislabels
			RampMultipleBD(bdID, channelsy, setpointy, ramprate=ramprate)
		endif

		// Record fast axis
		fdacRecordValues(fdID,i,channelsx,startxs,finxs,numptsx,delay=delayy,ramprate=ramprate,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)
	endfor

	// Save by default
	if (nosave == 0)
  		SaveWaves(msg=comments, fastdac=1)
  	else
  		dowindow /k SweepControl
	endif
end


function ScanfastdacRepeat(instrID, start, fin, channels, sweeprate, numptsy, [numptsx, sweeprate, delayy, ramprate, alternate, comments, RCcutoff, numAverage, notch, nosave])
	// 1D repeat scan for FastDAC
	// Note: to alternate scan direction set alternate=1
	// Note: Ramprate is only for ramping gates between scans
	variable instrID, start, fin, numptsy, numptsx, sweeprate, delayy, ramprate, RCcutoff, numAverage, alternate, nosave,
	string channels, comments, notch
	string x_label
	variable i=0, j=0

	if (!paramisdefault(alternate))
		abort "Not implemented alternating direction scans yet"
	endif



	// Chose which input to use for numpts of scan
	if (ParamIsDefault(numpts) && ParamIsDefault(sweeprate))
		abort "ERROR[ScanFastDac]: User must provide either numpts OR sweeprate for scan [neither provided]"
	elseif (!ParamIsDefault(numpts) && !ParamIsDefault(sweeprate))
		abort "ERROR[ScanFastDac]: User must provide either numpts OR sweeprate for scan [both provided]"
	elseif (!ParamIsDefault(numpts)) // If numpts provided, just use that
		numpts = numpts
	elseif (!ParamIsDefault(sweeprate)) // If sweeprate provided calculate numpts required
		numpts = get_numpts_from_sweeprate(fdID, start, fin, sweeprate)
	endif

	// Reconnect instruments
	sc_openinstrconnections(0)

	// Set defaults
	nvar fd_ramprate
	ramprate = ParamIsDefault(ramprate) ? fd_ramprate : ramprate
	delayy = ParamIsDefault(delayy) ? 0 : delayy
	if (paramisdefault(notch))
		notch = ""
	endif
	if (paramisdefault(comments))
		comments = ""
	endif

	// Ramp to startx and format inputs for fdacRecordValues
	string starts = "", fins = ""
	RampMultipleFD(instrID, channels, start)
	fd_format_setpoints(start, fin, channels, starts, fins)

	// Let gates settle
	sc_sleep(delayy)

	// Get labels for waves
	if (paramisdefault(x_label))
		x_label = GetLabel(channels, fastdac=1)
	endif
	if (paramisdefault(y_label))
		y_label = "Repeats"
	endif

	// Make waves
	InitializeWaves(start, fin, numpts, x_label=x_label, y_label=y_label, starty=starty, finy=finy, numptsy=numy, fastdac=1)

	// Main measurement loop
	variable d=1
	for (j=0; j<numy; j++)
		if (alternate!=0) // If want to alternate scan scandirection
			if (d>0)
				fd_format_setpoints(start, fin, channels, starts, fins) // Put into starts and fins
			elseif (d<0)
				fd_format_setpoints(fin, start, channels, starts, fins) // Put into starts and fins
			endif
			d = d*-1
		endif

		// Record values for 1D sweep
		fdacRecordValues(instrID,j,channels,starts,fins,numpts,delay=delayy, ramprate=ramprate,RCcutoff=RCcutoff,numAverage=numAverage,notch=notch)

	endfor
	// Save by default
	if (nosave == 0)
  		SaveWaves(msg=comments, fastdac=1)
  	else
  		dowindow /k SweepControl
	endif
end



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Macros //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAMacros()
end

function Scan3DTemplate()
	//Template loop for varying up to three parameters around any scan
	// nvar fastdac, bd6
	string buffer
	variable i, j, k
	make/o/free Var1 = {0}
	make/o/free Var2 = {0}
	make/o/free Var3 = {0}

	i=0; j=0; k=0
	do // Loop to change k var3
		//RAMP VAR 3
		do	// Loop for change j var2
			//RAMP VAR 2
			do // Loop for changing i var1 and running scan
				// RAMP VAR 1
				sprintf buffer, "Starting scan at Var1 = %.1fmV, Var2 = %.1fmV, Var3 = %.1fmV\r", Var1[i], Var2[j], Var3[k]
				//SCAN HERE
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


function steptempscanSomething()
	// nvar bd6, srs1
	svar ls370

	make/o targettemps =  {300, 275, 250, 225, 200, 175, 150, 125, 100, 75, 50, 40, 30, 20}
	make/o heaterranges = {10, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 1, 1, 1, 1}
	setLS370exclusivereader(ls370,"bfsmall_mc")

	variable i=0
	do
		setLS370PIDcontrol(ls370,6,targettemps[i],heaterranges[i])
		sc_sleep(2.0)
		WaitTillTempStable(ls370, targettemps[i], 5, 20, 0.10)
		sc_sleep(60.0)
		print "MEASURE AT: "+num2str(targettemps[i])+"mK"

		//SCAN HERE

		i+=1
	while ( i<numpnts(targettemps) )

	// kill temperature control
	turnoffLS370MCheater(ls370)
	resetLS370exclusivereader(ls370)
	sc_sleep(60.0*30)

	// 	SCAN HERE for base temp
end
