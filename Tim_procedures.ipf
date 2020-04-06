#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Waves Average>  //TODO: what does this do?
#include <Function Grapher>





macro DCleakagetest()  // Used ~ Jan2020
	rampmultiplebd(bd6, "12", 0, ramprate=1000)
	timsleep(1)
	print read34401A(dmm4)
	rampmultiplebd(bd6, "12", 30, ramprate=1000)
	timsleep(2)
	print read34401A(dmm4)
	doAlert/T="Massive jump?" 1, "Want to continue?"
	if(V_flag == 2)
		rampmultiplebd(bd6, "12", 0, ramprate=1000)
		abort "Aborted, something wrong with DC current"
	endif
	rampmultiplebd(bd6, "12", -250, ramprate=1000)
	timsleep(5)
	scanbabydac(bd6, -250, 250, "12", 101, 0.001, 1000)
	rampmultiplebd(bd6, "12", 0, ramprate=1000)

end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Scans /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAScans()
End

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

//function ScanFastDacRepeat(fastdac, startx, finx, channelsx, numptsx, numptsy, delayy, xlabel, [offsetx, comments, RCcutoff, numAverage, notch]) //Units: mV, mT
//	// x-axis is the dac sweep
//	// y-axis is an index
//	// this will sweep: start -> fin, fin -> start, start -> fin, ....
//	// each sweep (whether up or down) will count as 1 y-index
//	// Data processing:
//	// 		- RCcutoff set the lowpass cutoff frequency
//	//		- average set the number of points to average
//	//		- nocth sets the notch frequencie, as a comma seperated list (width is fixed at 5Hz)
//
//	//TODO: Make this work with multiple channels. Each comma separated channel needs a comma separated start and fin string
//
//	variable fastdac, startx, finx, numptsx, numptsy, delayy, offsetx, RCcutoff, numAverage
//	string xlabel, channelsx, comments, notch
//	variable i=0, setpointx, setpointy
//	string x_label, y_label
//
//	if(paramisdefault(comments))
//		comments=""
//	endif
//
//	if( ParamIsDefault(offsetx))
//		offsetx=0
//	endif
//
//	// setup labels
//	x_label = xlabel
//	y_label = "Sweep Num"
//
//	// intialize waves
//	variable starty = 0, finy = numptsy-1, scandirection=0
//	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label, fastdac=1)
//
//	//RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
//
//	rampOutputfdac(fastdac, str2num(channelsx), startx)
//	sc_sleep(0.2)
//	string sx, fx  //startx and finx (which will switch back and forth between real startx and finx)
//	do
//		if(mod(i,2)==0)
//			sx = num2str(startx)
//			fx = num2str(finx)
//		else
//			sx = num2str(finx)
//			fx = num2str(startx)
//		endif
//
//		rampOutputfdac(fastdac, str2num(channelsx), str2num(sx))
//		sc_sleep(delayy) // wait at start point
//		fdacRecordValues(fastdac, i, channelsx, sx, fx, numptsx, RCcutoff=RCcutoff, numAverage=numAverage, notch=notch)  //1D sweep either forwards or backwards
//		i+=1
//	while (i<numptsy)
//	SaveWaves(msg=comments, fastdac=1)
//end
//
//
//function ScanFastDAC(fd, start, fin, channels, numpts, ramprate, [comments, nosave, RCcutoff, numAverage, notch]) //Units: mV
//	variable fd, start, fin, numpts, ramprate, nosave, RCcutoff, numAverage
//	string channels, comments, notch
//	string x_label
//
//	if(paramisdefault(comments))
//	comments=""
//	endif
//
//	x_label = GetLabel(channels)
//
//	//Ramp to start
//	rampOutputfdac(fd, str2num(channels), start, ramprate=ramprate)
//	sc_sleep(0.5)
//	InitializeWaves(start, fin, numpts, x_label=x_label, fastdac=1)
//	fdacRecordValues(fd, 0, channels, num2str(start), num2str(fin), numpts, RCcutoff=RCcutoff, numAverage=numAverage, notch=notch)
//
//	if (nosave == 0)
//  		SaveWaves(msg=comments)
//  	else
//  		dowindow /k SweepControl
//	endif
//
//end
//
//
//function ScanFastDac2D(bd, fd, startx, finx, channelsx, numptsx, starty, finy, channelsy, numptsy, [delayy, ramprate, setchargesensor, comments, RCcutoff, numAverage, notch])
//	//ramprate is how fast to ramp back to beginning of scan
//	variable bd, fd, startx, finx, numptsx, starty, finy, numptsy, delayy, ramprate, setchargesensor, RCcutoff, numAverage
//	string channelsx, channelsy, notch, comments
//
//	variable/g sc_scanstarttime = datetime
//
//	ramprate = paramisdefault(ramprate) ? 5000 : ramprate
//
//	string/g sc_y_label, sc_x_label
//	//sc_x_label = getfdlabel(channelsx)
//	//TODO: Make getfdlabel
//	sc_y_label = getlabel(channelsy)
//
//	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=sc_x_label, y_label=sc_y_label, fastdac=1)
//
//	variable i, rt
//	rampmultiplebd(bd, channelsy, starty, ramprate=1000)
//	rampOutputfdac(fd, str2num(channelsx), startx, ramprate=ramprate)
//	i = 0
//	do
//		rampmultiplebd(bd, channelsy, starty+i*((finy-starty)/(numptsy-1)), ramprate=1000)
//
//		if (setchargesensor == 1)
//			rampOutputfdac(fd, str2num(channelsx), round((startx+finx)/2), ramprate=ramprate)
//			//setchargesensorfd(fd, bd)
//			//TODO: Put this back in!
//			rampOutputfdac(fd, str2num(channelsx), startx, ramprate=ramprate)
//		endif
//
//		sc_sleep(delayy)
//		fdacRecordValues(fd, i, channelsx, num2str(startx), num2str(finx), numptsx, RCcutoff=RCcutoff, numAverage=numAverage, notch=notch)
//	while (i<numptsy)
//	SaveWaves(msg=comments, fastdac=1)
//end


//function ScanFastDac2DLine(bd, fd, startx, finx, channelsx, numptsx, x_label, starty, finy, channelsy, numptsy, delayy, width, [comments, rampratex, rampratey, x1, y1, x2, y2, linecut, followtolerance, startrange])//Units: mV
//	variable bd, fd, startx, finx, numptsx, starty
//	variable finy, numptsy, delayy, rampratey, rampratex, x1, y1, x2, y2, width, linecut
//	variable followtolerance, startrange
//	//startrange = how many mV to look from end of scan range in x for first transition
//	// findthreshold = tolerance in findtransition (~1 is high (not very reliable), 5 is low (very reliable))
//	string channelsx, x_label, channelsy, comments
//	variable i=0, j=0, setpointx, setpointy, ft = followtolerance, threshold
//	string y_label = getlabel(channelsy)
//
//	svar VKS = $getVKS()  //Global VariableKeyString so it can be passed and altered by the function (e.g. Cut2Dlines)
//	VKS = ""  // Reset global string
//
//	startrange = paramIsDefault(startrange) ? 150 : startrange
//	rampratex = paramisdefault(rampratex) ? 5000 : rampratex //Max speed by default
//	if (startx >= finx)
//		abort "Please make start x less than fin x"
//	endif
//
//
//	if(paramisdefault(x1) || paramisdefault(x2) || paramisdefault(y1) || paramisdefault(y2))
//		variable sy, numx
//		wave FastScan //uses charge transition to find positions and gradient
//		print "Scanning two lines to calculate initial gradient and transition coords"
//		numx = round(abs(startx-finx) < 100 ? 100 : abs(startx - finx)) //numx is larger of 100points or every 1mV
////		if (startattop == 1)
////			sy = starty < finy ? finy : starty //sets sy to higher of starty/finy to scan from top down
//		if (starty > finy) //If starting from top of scan
////			sy = starty
//			rampfd(fd, channelsx, startx)
//			rampmultiplebd(bd, channelsy, starty)
//			sc_sleep(0.1)
//			setchargesensorfd(fd, bd)  //Uses default SetChargeSensor setting
//			FD1D(fd, channelsx, startx, startx+startrange, startrange*4, delayx, ramprate=rampratex, ADCchannels="0") //Hard coded to use FD0 as Charge sensor //Leaves scan in FastScan
//		else //Starting from bottom
//			rampfd(fd, channelsx, finx-startrange)
//			rampmultiplebd(bd, channelsy, starty)
//			sc_sleep(0.1)
//			setchargesensorfd(fd, bd)  //Uses default SetChargeSensor setting
//			FD1D(fd, channelsx, finx-startrange, finx, startrange*4, delayx, ramprate=rampratex, ADCchannels="0") //Hard coded to use FD0 as Charge sensor //Leaves scan in FastScan		endif
//		endif
//
//		x1 = findtransitionmid(FastScan, threshold=threshold)
//		if(numtype(x1) == 2) //if didn't find it there, try other part
//			doAlert/T="Didn't find transition" 1, "Do you want to see the rest of the scan region?"
//			if(V_flag == 2) //No clicked
//				abort "Didn't want to look in rest of range"
//			endif
//			FD1D(fd, channelsx, startx, finx, 1001, delayx, ramprate=rampratex, ADCchannels="0") //Hard coded to use FD0 as Charge sensor //Leaves scan in FastScan		endif
//			Killwindow/z FastScan0  //Attempt to not clutter, but not sure if it will have this name each time.
//			Display/N=FastScan Fastscan
//			abort "Restart Scan with new parameters"
//		endif
//
////		y1 = sy
//		y1 = starty
//		rampmultiplebd(bd, channelsy, starty+5, ramprate = 1000)
//		FD1D(fd, "0", x1-startrange/2, x1+startrange/4, startrange*3, delayx, ADCchannels="0") //only checks near to previous transition
//		x2 = findtransitionmid(FastScan, threshold=threshold)
//		if(numtype(x2) == 2)
//			abort "failed to find charge transition at first row +5mV"
//		endif
//		y2 = starty+5
//		print "x1 = " + num2str(x1) + ", " + "y1 = " + num2str(y1) + ", " + "x2 = " + num2str(x2) + ", " + "y2 = " + num2str(y2) //useful if you want to run the same scan multiple times
//	endif
//
//	VKS = replacenumberbykey("x1", VKS, x1)
//	VKS = replacenumberbykey("x2", VKS, x2)
//	VKS = replacenumberbykey("y1", VKS, y1)
//	VKS = replacenumberbykey("y2", VKS, y2)
//	VKS = replacenumberbykey("w", VKS, width)
//
//	string/g sc_y_label
//	sc_y_label = getlabel(channelsy)
//
//
//	InitializeFastScan2D(0, width, numptsx, starty, finy, numptsy, ADCchannels)
//	make/o/n=(ceil(abs(finx-startx)/width*numptsx), numptsy) FullScan //For displaying the full scan, but not saved
//	setscale /i x, startx, finx, FullScan
//	setscale /i y, starty, finy, FullScan
//
//	if (linecut == 1)
//		variable/g sc_is2d = 2
//		make/o/n=(numptsy) sc_linestart
//		setscale /i x, starty, finy, sc_linestart
//	endif
//	VKS = replacenumberbykey("x1", VKS, x1)
//	VKS = replacenumberbykey("x2", VKS, x2)
//	VKS = replacenumberbykey("y1", VKS, y1)
//	VKS = replacenumberbykey("y2", VKS, y2)
//	VKS = replacenumberbykey("w", VKS, width)
//	//VKS = replacenumberbykey("n", VKS, 0) 		//used by Cut2Dline for adapting line
//
//
//  	// main loop
//  	variable/g sc_scanstarttime = datetime
//  	variable sx, fx
//  	wave FastScan, FastScan_2d, FastScanCh0, FastScanCh1, FastScanCh0_2d, FastscanCh1_2d, FastScanCh2, FastScanCh3, FastScanCh2_2d, FastscanCh3_2d
//	do
//		setpointy = starty + (i*(finy-starty)/(numptsy-1))
//		Cut2Dline(startx = sx, finx = fx, y = setpointy, followtolerance=followtolerance) //Returns startx and finx of scan line in sx and fx
//		sc_linestart[i] = sx
////		sx = sx < startx ? startx : sx
////		fx = fx > finx ? finx : fx
////
//	  	RampMultipleBD(bd, channelsy, setpointy, ramprate=rampratey)
//		rampfd(fd, channelsx, sx)
//		sc_sleep(delayy)
//		setchargesensorfd(fd, bd)
//
//		FD1D(fd, channelsx, sx, fx, numptsx, delayx, ADCchannels=ADCchannels, ramprate=rampratex, delayy=delayy)  //Creates 1D wave called 'FastScan1D'
//		//joshsweep(fd,0,0,1,1001,1e-6)
//
//		switch (strlen(ADCchannels))
//			case 1:
//				FastScan_2d[][i] = FastScan[p]
//				break
//			case 2:
//				FastScanCh0[] = FastScan[2*p]
//				FastScanCh1[] = FastScan[2*p+1]
//				FastScanCh0_2d[][i] = FastScan[2*p]
//				FastScanCh1_2d[][i] = FastScan[2*p+1]
//				break
//			case 4:
//				FastScanCh0[] = FastScan[4*p]
//				FastScanCh1[] = FastScan[4*p+1]
//				FastScanCh0_2d[][i] = FastScan[4*p]
//				FastScanCh1_2d[][i] = FastScan[4*p+1]
//				FastScanCh2[] = FastScan[4*p+2]
//				FastScanCh3[] = FastScan[4*p+3]
//				FastScanCh2_2d[][i] = FastScan[4*p+2]
//				FastScanCh3_2d[][i] = FastScan[4*p+3]
//				break
//			default:
//				abort "Not implemented yet"
//		endswitch
//
//		// TODO: Make FullScan update... hard to figure out where to put in values into matrix??
//
//		doupdate
//
//		// tell cutfunc another line is completed
//		i+=1
//		VKS = ReplaceNumberByKey("n", VKS, i) //Tells cut func which row has finished being scanned
//	while (i<numptsy)
//
//  Savewavesfast(ADCchannels)
//end



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

function ScanFastDACslow(instrID, start, fin, channels, numpts, delay, ramprate, [comments, nosave]) //Units: mV
	// sweep one or more fastDAC channels in old slow way
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
	RampMultiplefdac(instrID, channels, setpoint, ramprate=ramprate)

	sc_sleep(1.0)
	InitializeWaves(start, fin, numpts, x_label=x_label)
	do
		setpoint = start + (i*(fin-start)/(numpts-1))
		RampMultiplefdac(instrID, channels, setpoint, ramprate=ramprate)
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
    if( a*(w[i] - value) < 0 )
      break
    endif
    i+=1
  while (i<numpts)

  if(scansave==1)
    SaveWaves(msg=comments)
  endif

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


//function ScanBabyDac2DLine(instrID, startx, finx, channelsx, stepmultiple, delayx, rampratex, starty, finy, channelsy, numptsy, delayy, rampratey, width, [x1, y1, x2, y2, comments, linecut, followtolerance, startrange, dmmid, findthreshold]) //Units: mV
//	variable instrID, startx, finx, stepmultiple, delayx, rampratex, starty
//	variable finy, numptsy, delayy, rampratey, x1, y1, x2, y2, width, linecut
//	variable followtolerance, startrange, dmmid, findthreshold
//	//startrange = how many mV to look from end of scan range in x for first transition
//	// findthreshold = tolerance in findtransition (~1 is high (not very reliable), 5 is low (very reliable))
//	string channelsx, channelsy, comments
//	variable i=0, j=0, setpointx, setpointy, ft = followtolerance, numptsx, threshold
//	string x_label, y_label
//	svar VKS = $getVKS()  //Global VariableKeyString so it can be passed and altered by the function (e.g. Cut2Dlines)
//	VKS = ""  // Reset global string
//
//	if((finx - startx)/(stepmultiple*0.076) < 20) //Easy to forget that it is stepmultiple instead of numptsx
//		doAlert/T="Check stepmultiple (not numptsx here!)" 1, "Do you really want to run a scan with only "\
//			+ num2istr((finx - startx)/(stepmultiple*0.076)) + " points per line? Remember stepmultiple is a multiple of minimum DAC step (0.76mV)"
//		if(V_flag == 2)
//			abort "Good choice"
//		endif
//	endif
//	numptsx = round(abs((finx-startx)/(stepmultiple*0.076)))
//
//	threshold = paramisdefault(findthreshold) ? 5 : findthreshold
//	startrange = paramIsDefault(startrange) ? 150 : startrange //gives default value if not specified
//	if(paramisdefault(comments))
//		comments=""
//	endif
////	wave sc_measAsync
////	wavestats/Q sc_measAsync
////	if (linecut == 1 && V_sum != 0)
////		abort "Can't measure asynchronously with linecut on, please untick boxes and try again"
////	endif
//
//	if(paramisdefault(x1) || paramisdefault(x2) || paramisdefault(y1) || paramisdefault(y2))
//		variable sy, numx
//		wave i_sense //uses charge transition to find positions and gradient
//		print "Scanning two lines to calculate initial gradient and transition coords"
//		numx = round(abs(startx-finx)/3 < 100 ? 100 : abs(startx - finx)/3) //shorthand if else. numx is larger of 100points or every 3mV
//		sy = starty < finy ? starty : finy //short if else statement. sets sy to lower of starty/finy to scan from bottom up
//		rampmultiplebd(instrID, channelsy, sy, ramprate = 1000)
//		rampmultiplebd(instrID, channelsx, finx-startrange, ramprate = 1000)
//		sc_sleep(0.5)
//		CorrectChargeSensor(instrid, dmmid)
////		scanbabydac(instrID, finx-abs(finx-startx)*(1-startdec), finx, channelsx, numx*(1-startdec), delayx, 1000, nosave = 1) //1 point per mV, first assuming transition is in last 1/4
//		scanbabydac(instrID, finx-startrange, finx, channelsx, startrange, delayx, 1000, nosave = 1) //1 point per mV
//		dowindow /k SweepControl
//		//x1 = fitcharge1d(i_sense)
//		x1 = findtransitionmid(i_sense, threshold=threshold)
//		if(numtype(x1) == 2) //if didn't find it there, try other part
//			doAlert/T="Didn't find transition" 1, "Do you want to look in the rest of the scan region?"
//			if(V_flag == 2) //No clicked
//				abort "Didn't want to look in rest of range"
//			endif
////			scanbabydac(instrID, startx, startx+startdec*abs(finx-startx), channelsx, numx*startdec, delayx, 1000, nosave = 1) //1 point per mV
//			scanbabydac(instrID, startx, finx-startrange, channelsx, round((finx-startrange-startx)/5), delayx, 1000, nosave = 1) //1 point per 5mV
//			dowindow /k SweepControl
//			//x1 = fitcharge1d(i_sense)
//			x1 = findtransitionmid(i_sense, threshold=threshold)
//			if(numtype(x1) == 2)
//				abort "failed to find charge transition in first row"
//			endif
//		endif
//		y1 = sy
//		rampmultiplebd(instrID, channelsy, sy+5, ramprate = 1000)
//		scanbabydac(instrID, x1-100, x1+20, channelsx, 121, delayx, 1000, nosave = 1) //only checks near to previous transition
//		dowindow /k SweepControl
//		//x2 = fitcharge1d(i_sense)
//		x2 = findtransitionmid(i_sense, threshold=threshold)
//		if(numtype(x2) == 2)
//			abort "failed to find charge transition at first row +5mV"
//		endif
//		y2 = sy+5
//		print "x1 = " + num2str(x1) + ", " + "y1 = " + num2str(y1) + ", " + "x2 = " + num2str(x2) + ", " + "y2 = " + num2str(y2) //useful if you want to run the same scan multiple times
//	endif
//
//	VKS = replacenumberbykey("x1", VKS, x1)
//	VKS = replacenumberbykey("x2", VKS, x2)
//	VKS = replacenumberbykey("y1", VKS, y1)
//	VKS = replacenumberbykey("y2", VKS, y2)
//	VKS = replacenumberbykey("w", VKS, width)
//	//VKS = replacenumberbykey("n", VKS, 0) 		//used by Cut2Dline for adapting line
//
//	sprintf x_label, "BD %s (mV)", channelsx
//	sprintf y_label, "BD %s (mV)", channelsy
//
//	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label, linecut=linecut)
//
//	sc_sleep(1.0)
//  	// main loop
//	do
//		j=0
//		setpointx = startx
//		setpointy = starty + (i*(finy-starty)/(numptsy-1))
//
//		do
//			setpointx = startx + (j*(finx-startx)/(numptsx-1))
//			if( Cut2Dline(x = setpointx, y = setpointy, followtolerance=ft) == 0 )
//				RecordValues(i, j, fillnan=1)
//				j+=1
//			else
//				break
//			endif
//		while( j<numptsx )
//
//		if (j == numptsx && i<numptsy-1)
//			i+=1
//			continue
//		elseif (j == numptsx && i >= numptsy-1)
//			print "No allowed values in final row"
//			break
//		endif
//
//	  	RampMultipleBD(instrID, channelsy, setpointy, ramprate=rampratey)
//  		RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
//		sc_sleep(delayy)
//
//		CorrectChargeSensor(instrid, dmmid)
//
//		do
//		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
//		  if( Cut2Dline(x = setpointx, y = setpointy) == 0 )
//		     RecordValues(i, j, fillnan=1)
//		  else
//    		  RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
//		     sc_sleep(delayx)
//		     RecordValues(i, j)
//		  endif
//		  j+=1
//		while (j<numptsx)
//		// tell cutfunc another line is completed
//		i+=1
//		VKS = ReplaceNumberByKey("n", VKS, i) //Tells cut func which row has finished being scanned
//	while (i<numptsy)
//
//  SaveWaves(msg=comments)
//end


function ScanBabyDAC2Dcut(instrID, startx, finx, channelsx, numptsx, delayx, rampratex, starty, finy, channelsy, numptsy, delayy, rampratey, func, [comments]) //Units: mV
  variable instrID, startx, finx, numptsx, delayx, rampratex, starty, finy, numptsy, delayy, rampratey
  string channelsx, channelsy, func, comments
  variable i=0, j=0, setpointx, setpointy
  string x_label, y_label

  if(paramisdefault(comments))
    comments=""
  endif

  FUNCREF cutFunc fcheck=$func

  sprintf x_label, "BD %s (mV)", channelsx
  sprintf y_label, "BD %s (mV)", channelsy

  // initialize waves
  InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)
  sc_sleep(1.0)

  	// main loop
	do
		j=0
		setpointx = startx
		setpointy = starty + (i*(finy-starty)/(numptsy-1))

		do
			setpointx = startx + (j*(finx-startx)/(numptsx-1))
			if( fcheck(setpointx, setpointy) == 0 )
				RecordValues(i, j, fillnan=1)
				j+=1
			else
				break
			endif
		while( j<numptsx )

		if (j == numptsx)
			i+=1
			continue
		endif

	  	RampMultipleBD(instrID, channelsy, setpointy, ramprate=rampratey)
  		RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
		sc_sleep(delayy)

		do
		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
		  if( fcheck(setpointx, setpointy) == 0 )
		     RecordValues(i, j, fillnan=1)
		  else
    		  RampMultipleBD(instrID, channelsx, setpointx, ramprate=rampratex)
		     sc_sleep(delayx)
		     RecordValues(i, j)
		  endif
		  j+=1
		while (j<numptsx)
		i+=1
	while (i<numptsy)

  SaveWaves(msg=comments)
end

function ScanBabyDAC3D(instrID, start, fin, channels, numpts, delay, ramprate, [comments]) //Units: mV
  // sweep one or more babyDAC channels
  // channels should be a comma-separated string ex: "0, 4, 5"
  // measure a 2D scan at each setpoint
  variable instrID, start, fin, numpts, delay, ramprate
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
  do
    setpoint = start + (i*(fin-start)/(numpts-1))
    RampMultipleBD(instrID, channels, setpoint, ramprate=ramprate)
    sc_sleep(delay)
	ScanBabyDAC2D(instrID, -3200, -5000, "12", 181, 0.1, 1000, -550, -250, "13", 61, 0.3, 1000)
	i+=1
  while (i<numpts)

end


function ScanBabyDAC_SRS(babydacID, srsID, startx, finx, channelsx, numptsx, delayx, rampratex, starty, finy, numptsy, delayy, [comments]) //Units: mV, mV
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

function ScanBabyDAC_freq(babydacID, srsID, startx, finx, channelsx, numptsx, delayx, rampratex, starty, finy, numptsy, delayy, [comments]) //Units: mV, mV
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
  SetSRSFrequency(srsID,setpointy)

  // initialize waves
  InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

  // main loop
  do
    setpointx = startx
    setpointy = starty + (i*(finy-starty)/(numptsy-1))
    RampMultipleBD(babydacID, channelsx, setpointx, ramprate=rampratex)
    SetSRSFrequency(srsID,setpointy)
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


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// End of Scans //////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///// My Scancontroller additions//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAMyScancontrollerAdditions()
end

function killgraphs()
	string opengraphs
	variable ii

	opengraphs = winlist("*",";","WIN:1")
	if(itemsinlist(opengraphs)>0)
		for(ii=0;ii<itemsinlist(opengraphs);ii+=1)
			killwindow $stringfromlist(ii,opengraphs)
		endfor
	endif
	sc_controlwindows("") // Kill all open control windows
end

function NikDiff(yname, xname, idxStr)
	// yname is the name of the y-array
	// xname is the name of the x-array
	// idxStr is the index as a string closed in brackets
	//    this is done to fool scancontroller into putting the proper index into the function
	// example: LiveDiff("g_sense", "sc_xdata", "[i]")
	string yname, xname, idxStr
	wave ywave=$yname
	wave xwave=$xname
	wave W_coef

	variable i=str2num(idxStr[1,strlen(idxStr)-2])

	if(i>0)
		variable dx = xwave[i]-xwave[i-1]
		variable min_step = 0.4
		variable n = ceil(min_step/dx)

		if(n<3)
			n=3
		endif
	else
		return NaN
	endif

	if(i<n)
		return NaN
	endif

	duplicate/FREE/O/R=[i-n, i] ywave yn 	//makes yn with last n yvalues
	Extract/FREE/O yn, yn, numtype(yn)!=0		//changes yn to be just numtypes of last n values

	if(sum(yn) != 0)
		return NaN
	else
		CurveFit /Q line ywave[i-n,i] /X=xwave /D
		return W_coef[1]
	endif
end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////// My Analysis ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAMyAnalysis()
end


function Display3VarScans(wavenamestr, [v1, v2, v3, uselabels, usecolorbar, diffchargesense, switchrowscols, scanset, showentropy])
// This function is for displaying plots from 3D/4D/5D scans (i.e. series of 2D scans where other parameters are changed between each scan)
//v1, v2, v3 are looking for indexes e.g. "3" or range of indexs e.g. "2, 5" of the other parameters to display
//v1gmax, v2gmax, v3gmax below are the number of different values used for each parameter. These need to be hard coded
//datstart below needs to be hardcoded as the first dat of the sweep array
//uselabels also requires some hard coded variables to be set up below
//Usecolorbar = 0 does not show colorscale, = 1 shows it
//diffchargesense differentiates charge sensor data in the y direction (may want to change direction of differentiation later)

// TODO:Currently works for 5D, will need some adjusting to work for 3D, 4D.
	string wavenamestr //Takes comma separated wave names e.g. "g1x2d, v5dc"
	string v1, v2, v3 // Charge Sensor Right, Chare Sensor total, Small Dot Plunger
	variable uselabels, usecolorbar, diffchargesense, switchrowscols, scanset, showentropy //set to 1 to use //TODO: make rows cols be right all the time


	variable datstart, v1start, v2start, v3start, v1step, v2step, v3step
	variable/g v1gmax, v2gmax, v3gmax

	if (paramisdefault(scanset))
		print "Using Default parameters"
		//	////////////////// SET THESE //////////////////////////////////////////////////
		//	datstart = 328
		//	v1gmax = 7; v2gmax = 5; v3gmax = 6 //Have to make global to use NumVarOrDefault...
		//	v1start = -200; v2start = -550; v3start = -200
		//	v1step = -50; v2step = -50; v3step = -100
		//	make/o/t varlabels = {"CSR", "CStotal", "SDP"}
		//	make/o/t axislabels = {"SDL", "SDR"} //y, x
		//	///////////////////////////////////////////////////////////////////////////////

		//	///////////////////////////////////////////////////////////////////////////////

	else
		switch (scanset)
			case 1:
				// Right side of NikV2 15th feb 2020
				datstart = 88
				v1gmax = 5; v2gmax = 5; v3gmax = 2 //Have to make global to use NumVarOrDefault...
				v1start = -100; v2start = -0; v3start = -300
				v1step = -100; v2step = -100; v3step = -500
				make/o/t varlabels = {"RCB", "RP", "RCSQ"}
				make/o/t axislabels = {"RCSS", "RCT"} //y, x
				break
			case 2:
				datstart = 139
				v1gmax = 8; v2gmax = 4; v3gmax = 1 //Have to make global to use NumVarOrDefault...
				v1start = 0; v2start = -100; v3start = 0
				v1step = -25; v2step = -50; v3step = 0
				make/o/t varlabels = {"LP", "LCSS", ""}
				make/o/t axislabels = {"LCT", "LCB"} //y, x
				break
		endswitch
	endif


	usecolorbar = paramisdefault(usecolorbar) ? 1 : usecolorbar
	diffchargesense = paramisdefault(diffchargesense) ? 1 : diffchargesense
	make/o/t varnames = {"v1g", "v2g", "v3g"}
	make/o/t varrangenames = {"v1range", "v2range", "v3range"}
	make/o/t varlistvals = {"v1vals", "v2vals", "v3vals"}

	variable check=0, i=0, j=0, k=0

	if (paramisdefault(v1))
		v1=""
		check+=1
	endif
	if (paramisdefault(v2))
		v2=""
		check+=1
	endif
	if (paramisdefault(v3))
		v3=""
		check+=1
	endif
	string/g v1g = v1, v2g = v2, v3g = v3 //Have to make global to use StrVarOrDefault because cant use $ inside function becuse Igor is stupid
	if (check == 3)
		abort "Select one or more values to see graphs"
	endif
	check = 0

	variable fixedvarval, n

	string v, str

	do
		v = StrVarOrDefault(varnames[i], "") // Makes v = one of the input string variables  equivalent to v = $varnames[i]
		if (itemsinlist(v, ",") == 1)
			fixedvarval = i
			check += 1
		endif
		i+=1
	while (i<3)
	if (check == 0)
		abort "Must specify value of one variable at least"
	endif


	i=0; j=0
	do
		str = varrangenames[i];	make/o/n=2 $str = NaN; wave vrname = $str    // Igor's stupid way of making a wave with a name from a text wave
		str = varlistvals[i]; make/o $str = NaN; wave vlname = $str

		v = StrVarOrDefault(varnames[i], "")
		vrname = str2num(StringFromList(p, v, ","))
		wavestats/q vrname
		n = numvarOrDefault(varnames[i]+"max", -1)-1 //-1 at end because counting starts at 0. Should never have to default to -1
		if (V_npnts == 0)
			vrname = {0, n} //effectively default to max range
		elseif (V_npnts == 1)
			vrname[1] = vrname[0] //Just same value twice so that calc vals works
		endif
		do  //fills val wave with all values wanted
			vlname[j] = vrname[0] + j
			j+=1
		while (j < vrname[1]-vrname[0]+1)
		redimension/n=(vrname[1]-vrname[0]+1) vlname
		if (vrname[1] > n)
			printf "Max range for %s is %d, automatically set to max\n", varlabels[i], n
			vrname[1] = n
		endif
		j=0
		i+=1
	while (i<numpnts(varnames))


	make/o datlist = NaN
	make/o varvals = NaN
	make/o varindexs = NaN
	variable c=0 //for counting what place in datlist
	i=0; j=0; k=0
	do  // Makes list of datnums to display
		do
			do
				str = varlistvals[0]; wave w0 = $str //v1vals = fast
				str = varlistvals[1]; wave w1 = $str //v2vals = medium
				str = varlistvals[2]; wave w2 = $str //v3vals = slow

				datlist[c] = datstart+w0[k]+w1[j]*v1gmax+w2[i]*v2gmax*v1gmax
				if (uselabels!=0)
					varindexs[c] = {{w0[k]}, {w1[j]}, {w2[i]}}
					varvals[c] = {{v1start+w0[k]*v1step}, {v2start+w1[j]*v2step}, {v3start+w2[i]*v3step}}
				endif
				c+=1
				k+=1
			while (k < numpnts(w0))
			k=0
			j+=1
		while (j < numpnts(w1))
		j=0
		i+=1
	while (i < numpnts(w2))
	redimension/n=(numpnts(w0)*numpnts(w1)*numpnts(w2), -1) datlist, varvals, varindexs //just removes NaNs at end of waves
	string rowcolvars = "012"
	rowcolvars = replacestring(num2str(fixedvarval), rowcolvars, "")
	str = varlistvals[str2num(rowcolvars[0])]; wave w0 = $str
	str = varlistvals[str2num(rowcolvars[1])]; wave w1 = $str
	//// TODO: make this unnecessary
	variable rows = numpnts(w0), cols = numpnts(w1)
	if (switchrowscols == 1)
		variable temp
		temp = rows
		rows = cols
		cols = temp
	endif
	//
	tilegraphs(datlist, wavenamestr, rows = rows, cols = cols, axislabels=axislabels, varlabels=varlabels, varvals=varvals, varindexs=varindexs, uselabels=uselabels, usecolorbar=usecolorbar, diffchargesense=diffchargesense, showentropy=showentropy)
end




function tilegraphs(dats, wavenamesstr, [rows, cols, axislabels, varlabels, varvals, varindexs, uselabels, usecolorbar, diffchargesense, showentropy]) // Need all of varlabels, varvals, varindexs to use them
	// Takes list of dats and tiles 4x4 by default or if specified
	// Designed to work with display3VarScans although it should work with other things. Might help to look at display3varscans to understand this though.
	wave dats
	string wavenamesstr //Can be one or multiple wavenames separated by "," e.g. "g1x2d, v5dc"
	variable rows, cols
	wave/t axislabels, varlabels
	wave varvals, varindexs
	variable uselabels, usecolorbar, diffchargesense, showentropy
	svar sc_colormap

	rows = paramisdefault(rows) ? 4 : rows
	cols = paramisdefault(cols) ? 4 : cols

	make/o/t/n=(itemsinlist(wavenamesstr, ",")) wavenames
	variable i=0, j=0
	make/o/t/n=(itemsinlist(wavenamesstr, ",")) wavenames
	do
		wavenames[i] = removeleadingwhitespace(stringfromlist(i, wavenamesstr, ","))
		i+=1
	while (i<(itemsinlist(wavenamesstr, ",")))
	string wn = "", activegraphs = "", wintext
	i=0;j=0
	do
		do
			sprintf wn, "dat%d%s", dats[i], wavenames[j]
			if (cmpstr(wn[-2,-1], "2d", 0))	// case insensitive
				if (diffchargesense!=0 && (stringmatch(wn, "*Ch0*") == 1 || stringmatch(wn, "*sense*")))
					duplicate/o $wn $wn+"diff"
					wn = wn+"diff"
					differentiate/dim=1 $wn
				endif
				display
				setwindow kwTopWin, enablehiresdraw=3
				appendimage $wn
				modifyimage $wn ctab={*, *, $sc_ColorMap, 0}//, margin(left)=40,margin(bottom)=25,gfSize=10, margin(right)=3,margin(top)=3
				//modifyimage $wn gfMult=75
				modifygraph gfMult=75, margin(left)=35,margin(bottom)=25, margin(right)=3,margin(top)=3
				if (usecolorbar != 0)
					colorscale /c/n=$sc_ColorMap /e/a=rc
				endif
				Label left, axislabels[0]
				Label bottom, axislabels[1]
				if (showentropy == 1)
					wave fitdata
					fitentropy(dats[i]);duplicate/o/free/rmd=[][3][0] fitdata, testwave
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])+"\r"+num2str(mean(testwave))
				else
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])
				endif
				//TextBox/C/N=vars/A=rb/X=0.00/Y=0.00/E=2 "v1=4, v2=5, v3=6"
				if (uselabels!=0)
					sprintf wintext, "v1=%d, v2=%d, v3=%d, %s=%.3GmV, %s=%.3GmV, %s=%.3GmV: %s", varindexs[i][0], varindexs[i][1], varindexs[i][2], varlabels[0], varvals[i][0], varlabels[1], varvals[i][1], varlabels[2], varvals[i][2], wn
					DoWindow/T kwTopWin, wintext
				endif
			else
				display $wn
				setwindow kwTopWin, enablehiresdraw=3
				if (showentropy == 1)
					wave fitdata
					fitentropy(dats[i]);duplicate/o/free/rmd=[][3][0] fitdata, testwave
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])+"\r"+num2str(mean(testwave))
				else
					TextBox/C/N=datnum/A=LT/X=1.00/Y=1.00/E=2 "Dat="+num2str(dats[i])
				endif
			endif
			activegraphs+= winname(0,1)+";"
			j+=1
		while (j < numpnts(wavenames))
		j=0
		i+=1
	while (i< numpnts(dats))
	string cmd1, cmd2
	variable maxw=33*cols, maxh=33*rows
	maxw = maxw > 100 ? 100 : maxw
	maxh = maxh > 100 ? 100 : maxh
	sprintf cmd1, "TileWindows/O=1/A=(%d,%d)/r/w=(0,0,%d, %d) ", rows, cols*itemsinlist(wavenamesstr, ","), maxw, maxh
	cmd2 = ""
	string window_string
	for(i=0;i<itemsinlist(activegraphs);i=i+1)
		window_string = stringfromlist(i,activegraphs)
		cmd1+= window_string +","

		cmd2 = "DoWindow/F " + window_string
		execute(cmd2)
	endfor
	execute(cmd1)
end


function fitentropy(datnum)
	variable datnum
	string datname
//	datname = "dat"+num2str(datnum)+"FastscanCh1_2d"
	datname = "dat"+num2str(datnum)+"g1x2d"
	wave loaddat=$datname  // sets dat to be dat...g2x2d
	duplicate/o loaddat, dat
	variable Vmid, theta, const, dS, dT
	variable i=0, datnumber
	wave w_sigma //for collecting erros from FuncFit
	make /O /N=(dimsize(dat,0)) datrow
	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", datrow

	//killwaves/z fitdata
	make/D /O /N=(dimsize(dat,1), 6, 3) fitdata  //last column is for storing other info like dat number, y scale


	//Make/D/N=5/O temp

	//W_coef[0] = {-3048,1.2,0,0.5,-0.00045}
	//W_coef[0] = {Vmid,theta,const,dS,dT}
	make/free/O tempwave =  {{-3048},{1.2},{0},{0.5},{-0.00045},{0}} //gets overwritten with data specific estimates before funcfit
	fitdata[][0,4][0] = tempwave[0][q]
	fitdata[0][5][0] = datnum


	i=0
	do
		datrow[] = dat[p][i]
		fitdata[i][5][2] = dimoffset(dat, 1)+i*dimdelta(dat, 1) // records y values in fitdata for use in plot entropy
		wavestats/Q datrow
		if (v_npnts < 50 && i < (dimsize(dat,1)-1)) //Send back to beginning if not enough points in datrow
			i+=1
			continue
		elseif (v_npnts < 50 && i >= (dimsize(dat,1)-1))
			break
		endif
		//W_coef[0] = {(v_MinLoc + (V_MaxLoc-V_minLoc)/2),v_maxloc-V_minloc,0,0.5,-0.00040}
		fitdata[i][0,4][0] = {{(v_MinLoc + (V_MaxLoc-V_minLoc)/2)},{-v_maxloc+V_minloc},{0},{0.5},{-0.50}}
		fitdata[i][0,4][2] = fitdata[i][q][0] //save initial guess in page3

//		FuncFit /Q Entropy1CK W_coef datrow /D
		FuncFit /Q Entropy1CK fitdata[i][0,4][0] datrow
		fitdata[i][0,4][1] = w_sigma[q] //Save errors on page2
		i+=1
	while (i<dimsize(dat, 1))
//	while (i<1)


end

function fitentropy1D(dat)

	wave dat

	variable Vmid, theta, const, dS, dT
	variable i=0

	make /O /N=(5) fitdata

	Make/D/N=5/O W_coef

	W_coef[0] = {-3048,1.2,0,0.5,-0.00045}
	//W_coef[0] = {Vmid,theta,const,dS,dT}

	wavestats /Q dat
	W_coef[0] = {(v_MinLoc + (V_MaxLoc-V_minLoc)/2),v_maxloc-V_minloc,0,0.5,-0.0080}

	display dat
	FuncFit /Q Entropy1CK W_coef dat /D

	fitdata[] = w_coef[p]



end



Function Entropy1CK(w,Vp) : FitFunc
	Wave w
	Variable Vp

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(Vp) = -(dT)*((Vp-Vmid)/(2*theta)-0.5*dS)*(cosh((Vp-Vmid)/(2*theta)))^(-2)+const
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ Vp
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = Vmid
	//CurveFitDialog/ w[1] = theta
	//CurveFitDialog/ w[2] = const
	//CurveFitDialog/ w[3] = dS
	//CurveFitDialog/ w[4] = dT

	return (w[4])*((Vp-w[0])/(2*w[1])-0.5*w[3])*(cosh((Vp-w[0])/(2*w[1])))^(-2)+w[2]
End


function makeEntropyFitWave(dat,row,fitdata)
	wave dat, fitdata
	variable row


	make /O /N=(dimsize(dat,0)) datxval
	make /O /N=(dimsize(dat,0)) fitwave

	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", datxval
	datxval =x
	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", fitwave

	make /O /N=5 coefs
	coefs[0,4]=fitdata[row][p][0]

	int i=0
	variable x=0

	do
		fitwave[i]= Entropy1CK(coefs, datxval[i])
		i+=1
	while (i<dimsize(dat,0))

end

function seefit(row)
	variable row

	wave fitdata
	string datname
//	datname = "dat"+num2str(fitdata[0][5][0])+"Fastscanch1_2d" //grabs datnumber from fitdata
	datname = "dat"+num2str(fitdata[0][5][0])+"g1x2d" //grabs datnumber from fitdata
	wave loaddat=$datname  // sets dat to be dat...g2x2d
	duplicate/o loaddat, dat //To make g2x match fastscan
	wave fitwave
	//killwindow/Z SeeEntropyFit
	display/N=SeeEntropyFit dat[][row]
	makeentropyfitwave(dat,row,fitdata)
	appendtograph fitwave
	ModifyGraph rgb(fitwave)=(0,0,65535)
	//setaxis bottom fitdata[row][0][0]-15, fitdata[row][0][0]+15   // reasonable axis around centre point
	TextBox/C/N=text0/A=LT "Dat"+num2str(fitdata[0][5][0])+" BD13: "+num2str(fitdata[row][5][2])+"mV"
	Label left "EntropyX"
	Label bottom "FD_SDP/50mV"
End

function PlotEntropy([ErrorCutOff])

	variable ErrorCutOff
	wave fitdata
	variable i=0

	duplicate/O fitdata displaydata  //should make a wave with just the dimension it needs TODO

	if (paramisdefault(ErrorCutOff))
		errorcutoff = 0.5
	endif

	do
		if (fitdata[i][3][1] > errorcutoff || abs(fitdata[i][3][0]) > 10) // remove unreliable entropy values
			displaydata[i][3][0] = NaN
		endif
		i+=1
	while (i<dimsize(fitdata,0))

	setscale/P x, fitdata[0][5][2], (fitdata[1][5][2]-fitdata[0][5][2]), displaydata // sets scale to y scale of original data
	dowindow/K EntropyPlot
	display/N=EntropyPlot displaydata[][3][0]
	ErrorBars displaydata Y,wave=(displaydata[*][3][1],displaydata[*][3][1])
	Label left "Entropy/Kb"
	TextBox/C/N=text0/A=MT "dat"+num2str(fitdata[0][5][0]) //prints datnumber stored in 050
	Label bottom "BD13 /mV"
	make/O/N=(dimsize(displaydata,0)) tempwave = ln(2)
	setscale/P x, fitdata[0][5][2], (fitdata[1][5][2]-fitdata[0][5][2]), tempwave
	appendtograph tempwave
	ModifyGraph rgb(tempwave)=(0,0,65535), grid(bottom)=1,minor(bottom)=1,gridRGB(bottom)=(24576,24576,65535,32767), nticks(bottom)=10,minor=0

end


function fitcharge1D(dat)
	wave dat
	variable Vmid, w
	redimension/N=-1 dat
	duplicate/FREE dat datSmooth
	wavestats/Q/M=1 dat //easy way to get num notNaNs (M=1 only calculates a few wavestats)
	w = V_npnts/10 //width to smooth by (relative to how many datapoints taken)
	smooth w, datSmooth	//Smooth dat so differentiate works better
	differentiate datSmooth /D=datdiff
	wavestats/Q/M=1 datdiff
	Vmid = V_minloc

	Make/D/O/N=5 W_coef
	wavestats/Q/M=1/R=(Vmid-10,Vmid+10) dat //wavestats close to the transition (in mV, not dat points)
					//Scale y,   y offset, theta(width), mid, tilt
	w_coef[0] = {-(v_max-v_min), v_avg, 	abs((v_maxloc-v_minloc)/10), 	Vmid, 0} //TODO: Check theta is a good estimate
	duplicate/O w_coef w_coeftemp //TODO: make /FREE
	funcFit/Q Chargetransition W_coef dat /D
	wave w_sigma
	if(w_sigma[3] < 2) //Check Vmid was a good fit (Highly dependent on fridge temp and other dac values e.g. sometimes <0.03 consistently)
		return w_coef[3]
	endif
	make/O/N=2 cm_coef = 0
	duplicate/O/R=(-inf, vmid-5) dat datline //so hopefully just the gradient of the line leading up to the transition and not including the transition
	curvefit/Q line kwCWave = cm_coef datline /D
	w_coef = w_coeftemp
	w_coef[1] = cm_coef[0]
	w_coef[4] = cm_coef[1]
	funcFit/Q Chargetransition W_coef dat /D	//try again with new set of w_coef
	if	(w_sigma[3] < 0.5)
		return w_coef[3]
	else
		print "Bad Vmid = " + num2str(w_coef[3]) + " +- " + num2str(w_sigma[3]) + " near Vmid = " + num2str(Vmid)
		return NaN
	endif
end

function fitchargetransition(dat)
	// Takes 2D dat, puts fit paramters in fitwave
	wave dat

	variable G2, Vmid, G0, theta, gam
	variable i=0


//	make /O /N=(dimsize(dat,1)) datrow
	make /O/Free /N=(dimsize(dat,0)) datrow


//	SetScale/P x dimoffset(dat,1),dimdelta(dat,1),"", datrow
	SetScale/P x dimoffset(dat,0),dimdelta(dat,0),"", datrow

	Make/D/N=5/O W_coef
//	W_coef[0] = {0.1e-9,1.64e-9,3,-3412,0}

//	make /O /N=(dimsize(dat,0), 5) fitdata
	make/o/n=(dimsize(dat,1), 5) fitdata
	do
//		datrow[] = dat[i][p]
		datrow[] = dat[p][i]

		wavestats /Q datrow
		w_coef[0] = {(v_max-v_min), v_avg, 20, (v_maxLoc+(V_maxLoc-V_minLoc)/2),0}

		FuncFit /Q Chargetransition W_coef datrow /D

		fitdata[i][] = w_coef[q]
		i+=1
//	while (i<dimsize(dat, 0))
	while (i<dimsize(dat, 1))

End

Function Chargetransition(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = G0*tanh((x - Vmid)/(2*Theta)) + gamma*x + G2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = G0
	//CurveFitDialog/ w[1] = G2
	//CurveFitDialog/ w[2] = Theta
	//CurveFitDialog/ w[3] = Vmid
	//CurveFitDialog/ w[4] = gamma

	return w[0]*tanh((x - w[3])/(2*w[2])) + w[4]*x + w[1]
End

//function makechargetransitionfit()
//	make/o/n=(numpnts(FastScan)) temp_transitionfit
//	variable i
//	for (i = 0; i < numpnts(FastScan); i++)
//		temp_transitionfit[i] = Chargetransition(fit_FastScan,
//	endfor
//end





function shiftdata(datawave)   //shifts data left until no more NaN's
	wave datawave
	int shift, i

	make /o /n=(numpnts(datawave)) outwave

	for (i=0; numtype(datawave[i])==2;i+=1)
	endfor

	shift = -i

	for (i=0; i <= (numpnts(datawave)-1+shift); i+=1)
		outwave[i] = datawave[i-shift]
	endfor

	for (i=i; i <= numpnts(datawave)-1; i+=1)
		outwave[i] = nan
	endfor
	datawave = outwave

end


//Takes a 2D wave, differentiates in either x or y direction, then plots troughs of differentiated wave as 0s or 1s. Planning to make do a linear fit to that.
function graddif(data, vertical, [threshlow, startx, finx, starty, finy]) // vertical = 0 >> differentiate horizontally																				// vertical = 1 >> differentiate vertically
	wave data
	int vertical
	variable threshlow, startx, finx, starty, finy
	duplicate /O data dat


	if (paramisdefault(startx))
		startx = 0
	endif
	if (paramisdefault(finx))
		finx = dimsize(dat, 1)
	endif
	if (paramisdefault(starty))
		starty = 0
	endif
	if (paramisdefault(finy))
		finy = dimsize(dat,0)
	endif


	make /O /N=(finy-starty, finx-startx)  fitwave


	Differentiate/DIM=(vertical) dat/D=datdif						//$(nameofwave(dat)+"_dif")


	if (paramisdefault(threshlow))
		threshlow = 0.5*wavemin(datdif)     //may want to play with ratio value. wavemin because differentiated waves have troughs
	endif

	Display;AppendImage datdif


	int i, j

	for (j=starty; j<=finy-1; j+=1)
		for (i=startx; i<=finx-1; i+=1)
			if (datdif[j][i]>threshlow)
				fitwave[j][i] = 0
			elseif (datdif[j][i]<=threshlow)
				fitwave[j][i] = 1
			else
				fitwave[j][i] = nan
			endif
		endfor
	endfor
	//display; appendimage fitwave
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////// End of My Analysis //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////// Measurement functionality   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAMeasurementFunctionality()
end


function SetupStandardEntropy([printchanges, keepphase])
	variable printchanges, keepphase
	//Sets HQPC, SRSfreq, SRStconst, SRSsensitivity, Magy, FD
	nvar bd6, fastdac, srs1, srs2, magy, srs4, dmm5, magz, magy
	variable SRSout = 350, SRSfreq=111.11, SRStconst=0.03, SRSsens = 100, SRSphase=90, HQPC = -960, fieldy = 20, DCheat = 0

	variable temp
	string tempstr
	CheckInstrIds(bd6, fastdac, srs1, srs2, srs4, dmm5, magz, magy)
	temp = getsrsamplitude(srs1)
	if (temp != SRSout)
		if (printchanges)
			printf "Changing SRS1out from %.1fmV to %.1fmV\r", temp, SRSout
		endif
		setsrsamplitude(srs1, SRSout)
	endif
	temp = getsrsphase(srs1)
	if (temp != SRSphase && keepphase == 0)
		if (printchanges)
			printf "Changing SRS1phase from %.1f to %.1f\r", temp, SRSphase
		endif
		setsrsphase(srs1, SRSphase)
	else
		printf "SRS1 phase left at %.1f\r", temp
	endif
	temp = getsrsfrequency(srs1)
	if (temp != SRSfreq)
		if (printchanges)
			printf "Changing SRS1freq from %.1fHz to %.1fHz\r", temp, SRSfreq
		endif
		setsrsfrequency(srs1, SRSfreq)
	endif
	temp = getsrstimeconst(srs1)
	if (temp != SRStconst)
		if (printchanges)
			printf "Changing SRS1tconst from %.3fs to %.3fs\r", temp, SRStconst
		endif
		setsrstimeconst(srs1, SRStconst)
	endif
	temp = getsrstimeconst(srs4)
	if (temp != SRStconst)
		if (printchanges)
			printf "Changing SRS4tconst from %.3fs to %.3fs\r", temp, SRStconst
		endif
		setsrstimeconst(srs4, SRStconst)
	endif
	temp = getsrssensitivity(srs1)
	if (temp != SRSsens)
		if (printchanges)
			printf "Changing SRS1sensitivity from %.1fmV to %.1fmV\r", temp, SRSsens
		endif
		setsrssensitivity(srs1, SRSsens)
	endif
	temp = getsrssensitivity(srs4)
	if (temp != SRSsens)
		if (printchanges)
			printf "Changing SRS4sensitivity from %.1fmV to %.1fmV\r", temp, SRSsens
		endif
		setsrssensitivity(srs4, SRSsens)
	endif
	temp = getls625field(magy)
	if ((temp-fieldy)>0.05)
		if (printchanges)
			printf "Changing Magy from %.1fmT to %.1fmT\r", temp, fieldy
		endif
		setls625fieldwait(magy, fieldy)
	endif
	wave/t old_dacvalstr
	tempstr = old_dacvalstr[15]
	if (str2num(tempstr) != HQPC)
		if (printchanges)
			printf "Changing HQPC from %smV to %.1fmV\r", tempstr, HQPC
		endif
		rampmultiplebd(bd6, "15", HQPC)
	endif
	tempstr = old_dacvalstr[3]
	if (str2num(tempstr) != DCheat)
		if (printchanges)
			printf "Changing DCheat from %smV to %.1fmV\r", tempstr, DCheat
		endif
		rampmultiplebd(bd6, "3", DCheat)
	endif
	if (str2num(tempstr) != 0)
		if (printchanges)
			printf "Changing DCbias(DAC3) from %smV to 0mV\r", tempstr
		endif
		rampmultiplebd(bd6, "3", 0)
	endif

end

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




Function/S GetVKS()
    SVAR/Z zVKS  //SDFR SetDataFolderReference
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


//function Cut2DlineFD(y, startx, finx) //returns startx and finx of next row to scan
//	variable y
//	variable &startx, &finx //To return values
//
//	svar VKS = $GetVKS() //VariableKeyString = "m; HighC; LowC; c; x1; x2; y1; y2, w, n" //High/LowC for other cut2d function. not needed here
//	variable m, c, n
//	m = numberbykey("m", VKS)
//	c = numberbykey("c", VKS)
//	n = numberbykey("n", VKS) //For keeping track of number of lines scanned
//
//	if (numtype(m)!=0 || numtype(c)!=0 || n >= 2)  //Calculating line equations if necessary
//		variable x1, x2, y1, y2, w //for calculating y = mx + c equations
//		w = numberbykey("w", VKS)
//
//		if(n == 0 || numtype(n) == 2) //For first time or if n is not set and defaults to NaN
//			x1 = numberbykey("x1", VKS)
//			x2 = numberbykey("x2", VKS)
//			y1 = numberbykey("y1", VKS)
//			y2 = numberbykey("y2", VKS)
//		elseif(ft == 0 && n >= 2) //If no finite tolerance
//			n = -2 			//will stop Cut2Dline from storing junk data into VKS
//			VKS = replacenumberbykey("n", VKS, -1) //when n = -1 is loaded next time it won't try calculate new eq
//		elseif(n >= 2 && ft!= 0) //enough rows to calculate new coords and finite tolerance
//			wave FastScan, FastScan2D, w_coef, sc_ydata, sc_linestart	//Fits to charge transition from charge sensor, funcfit stores values in W_coef, sc_ywave has y values of data, sc_linestart has first x position of isense_2d data
//			nvar sc_is2d
//			variable i = 0, nend
//		//TODO: Won't always be stored in FastScan or fastscan2d. Depends on whether one or two channels read. Maybe just copy I_sense data into FastScan if necessary??
//			if(n < (ceil(10/dimdelta(sc_ydata,0))) && dimdelta(sc_ydata,0) < 5) //If there isn't enough data to do 10mV in y direction use all gathered so far
//				nend = n
//			elseif (dimdelta(sc_ydata,0)<5) //otherwise use enough data to cover 10mV
//				nend = ceil(10/dimdelta(sc_ydata,0))
//			else
//				nend = 2 // if ydata is sparse (i.e. quick scan) just use previous two points for gradient
//			endif
//
//			make/Free/O/N=(nend,2) coords = NaN	 //to store multiple transition coords
//			do //Find previous x and y coords of transitions
//				duplicate/FREE/O/RMD=[][(n-1)-i] FastScan2D datrow
//				if(sc_is2d == 2) //only necessary for line cut
//					setscale/P x, sc_linestart[(n-1)-i], dimdelta(i_sense2d, 0), datrow //Need to give correct dimensions before fitting
//				endif
//				coords[i][0] = fitcharge1d(datrow)
//				coords[i][1] = sc_ydata[(n-1)-i]
//				i+=1
//			while (i<nend)
//
//
//end

//function Cut2Dline([x, y, followtolerance, startx, finx]) //tests if x, y lie within lines defined in VKS. Returns 1 for Yes, 0 for No, or returns startx and finx of next line scan if used for fastscan
//	//followtolerance will adapt line equation up to tolerance (0.1 = 10% change)
//	variable x, y, followtolerance
//	variable &startx, &finx //For returning start and fin if being used by FastScan2D
//	svar VKS = $GetVKS() 	//VariableKeyString (global so it can storechanges)   VKS = "m; HighC; LowC; x1; x2; y1; y2"
//
//	variable m, HighC, LowC, c, ft = followtolerance, n, FS=0  //High/Low for the two y = mx+c equations, FS just to set whether fastscan or not
//
//	if (!paramisdefault(startx) || !paramisdefault(finx)) //If either not default, check all not default
//		if (paramisdefault(startx) || paramisdefault(finx) || paramisdefault(y))
//			abort "Need startx, finx, and y to return startx and finx"
//		else
//			FS=1
//			wave FastScan, sc_xdata
//			if (dimsize(fastscan,0) != numpnts(sc_xdata))
//				wave i_sense2d = FastScanCh0_2D //Assumes I_sense data is on FastADC0
//			else
//				wave i_sense2d = FastScan2D //Hopefully makes compatible with rest of code
//			endif
//		endif
//	elseif (!paramisdefault(x) || !paramisdefault(y))
//		if (paramisdefault(x) || paramisdefault(y))
//			abort "Need x and y to return whether in cut line or not"
//			wave i_sense2d
//		endif
//	else
//		abort "Something horribly wrong, need more inputs"
//	endif
//
//
//	m = numberbykey("m", VKS)
//	HighC = numberbykey("HighC", VKS)
//	LowC = numberbykey("LowC", VKS)
//	c = numberbykey("c", VKS) //Used for FastScan
//	n = numberbykey("n", VKS) //Used for followfunction
//
//	//caluclates Line equation from coords or previous data lines if necessary
//	if (numtype(m)!=0 || numtype(HighC)!=0 || numtype(LowC)!=0 || n >= 2)  //Calculating line equations if necessary
//		variable x1, x2, y1, y2, w //for calculating y = mx + c equations
//
//		w = numberbykey("w", VKS)
//		if(n == 0 || numtype(n) == 2) //For first time or if n is not set and defaults to NaN
//			x1 = numberbykey("x1", VKS)
//			x2 = numberbykey("x2", VKS)
//			y1 = numberbykey("y1", VKS)
//			y2 = numberbykey("y2", VKS)
//		elseif(ft == 0 && n >= 2) //If no finite tolerance
//			n = -2 			//will stop Cut2Dline from storing junk data into VKS
//			VKS = replacenumberbykey("n", VKS, -1) //when n = -1 is loaded next time it won't try calculate new eq
//		elseif(n >= 2 && ft!= 0) //enough rows to calculate new coords and finite tolerance
//			wave w_coef, sc_ydata, sc_linestart	//Fits to charge transition from charge sensor, funcfit stores values in W_coef, sc_ywave has y values of data, sc_linestart has first x position of isense_2d data
//			nvar sc_is2d
//			variable i = 0, nend
//
//			if(n < (ceil(abs(10/dimdelta(sc_ydata,0)))) && abs(dimdelta(sc_ydata,0)) < 5) //If there isn't enough data to do 10mV in y direction use all gathered so far
//				nend = n
//			elseif (abs(dimdelta(sc_ydata,0))<5) //otherwise use enough data to cover 10mV
//				nend = ceil(abs(10/dimdelta(sc_ydata,0)))
//			else
//				nend = 2 // if ydata is sparse (i.e. quick scan) just use previous two points for gradient
//			endif
//
//			make/Free/O/N=(nend,2) coords = NaN	 //to store multiple transition coords
//			do //Find previous x and y coords of transitions
//				duplicate/FREE/O/RMD=[][(n-1)-i] i_sense2d datrow
//				if(sc_is2d == 2) //only necessary for line cut
//					setscale/P x, sc_linestart[(n-1)-i], dimdelta(i_sense2d, 0), datrow //Need to give correct dimensions before fitting
//				endif
//				coords[i][0] = fitcharge1d(datrow)
//				coords[i][1] = sc_ydata[(n-1)-i]
//				i+=1
//			while (i<nend)
//
//			wavestats/Q/M=1/RMD=[][0] coords
//			if(V_numnans/dimsize(coords,0) < 0.5 && dimsize(coords,0) - V_numNans >= 2) //if at least 50% successful fits	and at least two data points make and check new m and Cs
//				curveFit/Q line, coords[][1] /X=coords[][0]
//				m = w_coef[1] 						//new gradient from linefit
//
//				variable oldm, TE // TE for ToleranceExceedNum number that I store in VKS
//				oldm = numberbykey("m", VKS)
//				TE = numberbykey("TolExceedNum", VKS) //Loads previous error code stored (NaN by default)
//				if(numtype(TE) == 2) //Sets TE to zero if first time being loaded
//					TE = 0
//				elseif(TE > 0.4)
//					TE = TE-0.4 		//so that E only causes abort if maxes out 5 times in a row, or more than ~40% of the time
//				endif
//				// Check to see if m has changed more than allowed by tolerance (Probably won't handle stationary points)
//				if(abs((m-oldm)/oldm) > ft)
//					print "m change by " +num2str(((m-oldm)/oldm)*100) + "% @ n = " + num2str(n) + ", TE @ " + num2str(TE+1)
//					m = oldm*(1+sign(abs(m)-abs(oldm))*ft) //increases/decreases m by max allowed amount
//					TE += 1 //increment Error value
//				endif
//				if(TE>4)
//					savewaves()
//					abort "Cut2Dline has changed gradient by max tolerance too many times in a row"
//				endif
//				VKS = replacenumberbykey("TolExceedNum", VKS, TE) //Stores total errors
//				VKS = replacenumberbykey("n", VKS, -1) //Prevent re-running this whole chunk of code until a new n value is stored by scan function
//				i = 0
//				do //get most recent nonNan transition coord
//					x1 = coords[i][0]; y1 = coords[i][1]
//					i+=1
//				while(numtype(x1)==2 && i<nend)
//				if(numtype(x1) == 0) //If good coord then calc high and low C
//					HighC = y1-m*(x1-sign(m)*w/2) 	//
//					LowC = y1-m*(x1+sign(m)*w/2)		//
//					c = y1-m*x1
//				else
//					if (FS == 1)
//						abort "Did not manage to make new gradient, waves not saved!!"
//					else
//						savewaves()
//					abort "Can't find x1, y1 to calc new C values"
//					endif
//				endif
//
//			else
//				VKS = replacenumberbykey("n", VKS, -1) //don't calc again until new row of data
//				n=-2	//don't store junk data in VKS
//			endif
//		else
//			abort "Cut2Dline Failed unexpectedly, waves not saved!!"
//		endif
//
//
//		if(n == 0 || numtype(n) == 2) //if first time through or not using n
//			m = ((y2-y1)/(x2-x1))
//			HighC = y1-m*(x1-sign(m)*w/2) //sign(m) makes it work for +ve or -ve gradient
//			LowC = y1-m*(x1+sign(m)*w/2)	//For both y = mx + c equations
//			c = y1-m*x1
//		endif
//
//
//		//If sanity checks passed/values made acceptable, or just first time through then store values
//		if(n != -2 ) //use this to prevent storing values
//			VKS = replacenumberbykey("m", VKS, m)				//stores line eq back in VKS
//			VKS = replacenumberbykey("HighC", VKS, HighC)
//			VKS = replacenumberbykey("LowC", VKS, LowC)
//			VKS = replacenumberbykey("c", VKS, c)
//			VKS = replacenumberbykey("n", VKS, -1) //prevent recalculating until new data row
//		endif
//	endif
//
//	w = numberbykey("w", VKS)
//	//Part that actually checks if x, y coords should be measured, or returns startx and finx for fastscan
//	if (FS == 1)
//		startx = (y-c)/m - w/2
//		finx = (y-c)/m + w/2
//	else
//		if ((y - m*x - LowC) > 0 && (y - m*x - HighC) < 0)
//			return 1
//		else
//			return 0
//		endif
//	endif
//
//end

//function CorrectChargeSensor(instrid, dmmid, [i, check, dcheat])
////Corrects the charge sensor to read 2nA as starting point, use 'i' if you want to print which line you're at
//	variable instrid, dmmid, i, check, dcheat //dcheat in uV
//	dcheat = paramisdefault(dcheat) ? 100 : dcheat
//	variable dmmval = 0, cdac5, na = dcheat/50  //calibrated at 2nA for 100uV
//	wave/T dacvalstr
//	dmmval = read34401A(dmmid)
//	if (abs(dmmval-na) > 0.02)
//		do
//			cdac5 = str2num(dacvalstr[5][1])
//			if (!paramisDefault(i))
//				print "Ramping DAC5 to " + num2str(cdac5+(na-dmmval)/0.1122*(2/na)) + "mV, at line " + num2str(i)
//			endif
//			if (check==0) //no user input
//				if (-340 < cdac5+(na-dmmval)/0.1122*(2/na) && cdac5+(na-dmmval)/0.1122*(2/na) < -270) //Prevent it doing something crazy
//					rampmultiplebd(instrid, "5", cdac5+(na-dmmval)/0.1122*(2/na), ramprate=100)
//				endif
//			else //ask for user input
//				doAlert/T="About to change DAC5" 1, "Scan wants to ramp DAC5 to " + num2str(cdac5+(na-dmmval)/0.1122*(2/na)) +"mV, is that OK?"
//				if (V_flag == 1)
//					rampmultiplebd(instrid, "5", cdac5+(na-dmmval)/0.1122*(2/na), ramprate=100)
//				else
//					abort "Computer tried to do bad thing"
//				endif
//			endif
//			dmmval = read34401A(dmmid)
//		while (abs(dmmval-na) > 0.05)
//	endif
//end

//function setoffsetfd(bdchannel, adcchannel, [setpoint, check, direction]) //Set direction 1 or -1 correction direction
//	string bdchannel, adcchannel
//	variable setpoint, check, direction
//	nvar bd6, fastdac
//	variable val, fdval
//
//	direction = paramisdefault(direction) ? 1 : direction
//	if (direction != 1 && direction != -1)
//		abort "Direction must be 1 or -1"
//	endif
//
//	wave/t oldfdValueString
//	wave/t dacvalstr
//	wave fastscan
//	fdval = str2num(oldfdValueString[3]) //Get fddac3 val
//	fd1d(fastdac, "3", fdval, fdval, 50, 1e-6, adcchannels=adcchannel)	 //Just measures at fddac3val, i.e. get single reading
//	doupdate
//	wavestats/q fastscan
//	val = V_avg //Average reading at setpoint
//
//	variable i=0, cdac, nextdac //Current dacval
//	if (abs(val-setpoint) > 0.001)
//		do
//			cdac = str2num(dacvalstr[str2num(bdchannel)][1])
//			if (val < setpoint)
//				nextdac = cdac-0.1*direction
//			elseif (val > setpoint)
//				nextdac = cdac+0.1*direction
//			else
//				print "Something weird happened in SetOffsetFD"
//				break
//			endif
//
//			if (check==0) //no user input
//				if (-50 < nextdac && nextdac < 50) 		//Prevent it doing something crazy
//					rampmultiplebd(bd6, bdchannel, nextdac, ramprate=100)
//				else
//					print "Could not correct offset"
//					break
//				endif
//			else //ask for user input
//				doAlert/T="About to change DAC"+bdchannel 1, "Scan wants to ramp DAC"+bdchannel+" to " + num2str(nextdac) +"mV, is that OK?"
//				if (V_flag == 1)
//					rampmultiplebd(bd6, bdchannel, nextdac, ramprate=1000)
//				else
//					abort "Computer tried to do bad thing"
//				endif
//			endif
//
//			fd1d(fastdac, "3", fdval, fdval, 20, 1e-6, adcchannels=adcchannel)	 //Just measures at fdval
//			doupdate
//			wavestats/q fastscan
//			val = V_avg //Average reading at setpoint
//			i+=1
//		while (abs(val-setpoint) > 0.002 && (i < 500))
//	else
//		printf "BD%s offset left unchanged at %smV\r", bdchannel, dacvalstr[str2num(bdchannel)][1]
//		return 0
//	endif
//
//	printf "BD%s offset set to %.2gmV\r", bdchannel, nextdac
//	sc_sleep(0.1)
//
//
//
//end

//function setchargesensorfd(fastdac, bd, [setpoint, check, offcenter])
//	variable fastdac, bd, setpoint, check, offcenter
//	variable val, fdval, cdac5
//	variable gradient = 0.08402 //0.1122
//	variable nextdac
//	setpoint = paramisdefault(setpoint) ? 0.8 : setpoint //Defaults to 0.8mV reading which is equivalent to 8nA with CS at 1e8 bias at 300uV
//	wave/t oldfdValueString
//	wave/t dacvalstr
//	wave fastscan
//	fdval = str2num(oldfdValueString[0])
//	if (offcenter!=0)
//		fd1d(fastdac, "0", fdval-1000, fdval-1000, 50, 1e-6)	 //Just measures at fdval
//	else
//		fd1d(fastdac, "0", fdval, fdval, 50, 1e-6)	 //Just measures at fdval
//	endif
//	doupdate
//	wavestats/q fastscan
//	val = V_avg //Average reading at setpoint
//
//	sc_sleep(0.1)
//
//	if (abs(val-setpoint) > 0.02)
//		do
//			cdac5 = str2num(dacvalstr[5][1])
//			nextdac = cdac5+(setpoint-val)/gradient // This uses gradient to calculate next dacval, works well if close already
//			if(abs(val-setpoint)>0.2) //if far away just move 1mV at a time
//				if (val < setpoint)
//					nextdac = cdac5+1
//				elseif (val > setpoint)
//					nextdac = cdac5-1
//				endif
//			endif
////			if (nextdac < -400)
////				nextdac = cdac5-10
////			elseif (nextdac > -150)
////				nextdac = cdac5 + 10
////			endif
//
//			if (check==0) //no user input
//				if (-500 < nextdac && nextdac < -100) 		//Prevent it doing something crazy
//					rampmultiplebd(bd, "5", nextdac, ramprate=100)
//				else
//					abort "Could not correct charge sensor"
//				endif
//			else //ask for user input
//				doAlert/T="About to change DAC5" 1, "Scan wants to ramp DAC5 to " + num2str(nextdac) +"mV, is that OK?"
//				if (V_flag == 1)
//					rampmultiplebd(bd, "5", nextdac, ramprate=1000)
//					print nextdac
//				else
//					abort "Computer tried to do bad thing"
//				endif
//			endif
//			if (offcenter!=0)
//				fd1d(fastdac, "0", fdval-1000, fdval-1000, 10, 1e-6)	 //Just measures at fdval
//			else
//				fd1d(fastdac, "0", fdval, fdval, 10, 1e-6)	 //Just measures at fdval
//			endif
//			doupdate
//			wavestats/q fastscan
//			val = V_avg //Average reading at setpoint
//
//		while (abs(val-setpoint) > 0.05)
//	endif
//	if (offcenter!=0)
//		rampfd(fastdac, "0", fdval, ramprate=50000)
//	endif
//
//	sc_sleep(0.1)
//end




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Macros //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAMacros()
end

function Scan3DTemplate()
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
//	notify("Finished all scans")
end


function MacroTemplate()
	nvar bd6, fastdac, srs1, srs2, magy, srs4
	string buffer
	svar ls370
	variable i, j, k, diff
	wave/t old_dacvalstr
	setls370exclusivereader(ls370, "bfsmall_mc")

	resetLS370exclusivereader(ls370)
	notify("Finished all scans")
end



//
//function ThetaCalibration()
////Start on a transition and it will continue to self center on that transition throughout the scans. Takes no heat transition measurement at range of temps
////with option to do multiple mag fields at each temp.
//	nvar bd6, srs1, fastdac, magy
//	svar ls370
//
//	make/o targettemps =  {300, 275, 250, 225, 200, 175, 150, 125, 100, 75, 60, 50, 40, 30, 20}
//	make/o heaterranges = {10, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 1, 1, 1, 1}
//	make/o/free fields = {0}//, -25}
//	setLS370exclusivereader(ls370,"bfsmall_mc")
//
//	setsrsamplitude(srs1, 0) //AC bias 0
//	rampmultiplebd(bd6, "3", 0) //DCbias 0
//
//	variable i=0, j=0
//	do
//		setLS370PIDcontrol(ls370,6,targettemps[i],heaterranges[i])
//		sc_sleep(2.0)
//		WaitTillTempStable(ls370, targettemps[i], 5, 20, 0.10)
//		sc_sleep(60.0)
//		print "MEASURE AT: "+num2str(targettemps[i])+"mK"
////		notify( "MEASURE AT: "+num2str(targettemps[i])+"mK")
//
//		do
////			setls625fieldwait(magy, fields[j])
////			timsleep(60)
//			centerontransition("12", fdx="0", width=60)
//			printf "Starting Theta Calibration scan at %.1fmK, %.1fmT\r", targettemps[i], fields[j]
//			ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", 2001, 0, 0, "7", 50, ADCchannels="0", xlabel="FD_SDP/1000mV", ramprate=100000, delayx=3e-3, delayy=0.1)
//			j+=1
//		while (j < numpnts(fields))
//		j=0
//		i+=1
//	while ( i<numpnts(targettemps) )
//
//	// kill temperature control
//	turnoffLS370MCheater(ls370)
//	resetLS370exclusivereader(ls370)
//	sc_sleep(60.0*30)
//	printf "Base temp is %.1fmK\r", getLS370temp(ls370, "mc")
//	do
//		setls625fieldwait(magy, fields[j])
//		timsleep(60)
//		centerontransition("12", fdx="0")
//		printf "Starting Theta Calibration scan at base temp, %.1fmT\r", targettemps[i], fields[j]
//		ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", 2001, 0, 0, "7", 50, ADCchannels="0", xlabel="FD_SDP/1000mV", ramprate=100000, delayx=5e-3, delayy=0.1)
//	while (j < numpnts(fields))
//	j=0
//	notify("Finished Theta Calibration Measurements")
//
//	setls625field(magy, 0)
//
//// 	ScanHere for base temp
//
//end
//
//
//function testHeatingVsField()
//// Aim is to see if changing perpendicular mag field affects the strange bumps we see in entropy signal for even occupation.
//
//	nvar fastdac, bd6, srs1, magy
//
//	make/o/free Var1 = {-50, -25, 0, 25, 50} //Field mT
//	make/o/free Var2 = {0}
//	make/o/free Var3 = {0}
//
//
//	variable i=0, j=0, k=0
//	do // Loop to change k var3
////		rampmultiplebd(bd6, "", Var3[k])
//		do	// Loop for change j var2
////			rampmultiplebd(bd6, "", Var2[j])
//			do // Loop for changing i var1 and running scan
//				setls625fieldwait(magy, Var1[i])
//				timsleep(60)
//				CenterOnTransition("12", fdx="0")
//				ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", 2001, 0, 0, "7", 40, delayy=0.2, delayx=5e-3, ramprate=100000, ADCchannels="02", xlabel="FD_SDP/50mV", printramptimes=0)
//				printf "Finished scan at Field = %.1fmT\r", Var1[i]//, Var2[i]//, Var3[j]
//				i+=1
//			while (i < numpnts(Var1))
//			i=0
//			j+=1
//		while (j < numpnts(Var2))
//		j=0
//		k+=1
//	while (k< numpnts(Var3))
//	notify("Finished all scans")
//
//end
//
//
//function ThetaDeltaESvsSRSout()
//
//	nvar fastdac, bd6, srs1
//	variable npts
//
//
////	make/o/free Var1 = {1,	1.5,	2,	2.5,	3,	3.5,	4,	4.5,	5,	5.5,	6,	6.5,	7,	7.5,	8,	8.5,	9,	9.5,	10}//,11,12,13,14,15,16,17,18,19,20} //nA
////	make/o/free Var1 = {1,	2,	3,	4,	5,	6,	7,	8,	9,	10}//,11,12,13,14,15,16,17,18,19,20} //nA
//	make/o/free Var1 = {2,	4,	6,	8,	10, 12, 15, 18, 21, 25}//,11,12,13,14,15,16,17,18,19,20} //nA
//	variable i=0
//
//	do // Loop for changing i va1r and running scan
////		rampmultiplebd(bd6, "", Var1[i])
//		setsrsamplitude(srs1, Var1[i]*50) //nA to mV output for lock in
//		CenterOnTransition("12", fdx="0")
//		printf "Starting scan at SRSout = %.1fnA, 150mV/s\r", Var1[i]
//		if (var1[i]<3.5)
//			npts = 50
//		else
//			npts = 50
//		endif
//		ScanFastDac2D(bd6, fastdac, -0-1000, -0+1000, "0", 9001, 0, 0, "7", npts, delayy=0.2, delayx = 1e-6, ramprate=20000, ADCchannels="0123", xlabel="FD_SDP/50mV")
//		i+=1
//	while (i < numpnts(Var1))
//	notify("Finished all Entropy vs ACbias")
//end
//
//
//
//
//function ThetaVsCSbias()
//
//	variable i = 0
//	nvar bd6, fastdac
//	make/o/free CSbias = {50,100, 200, 300, 400, 500} //200, 0, 50,
//	make/o/n=(numpnts(CSbias)) ThetaVsBias = NaN
//	setscale/i x, CSbias[0], CSbias[numpnts(CSbias)-1], ThetaVsBias
//
//	wave fitdata //Returned by fitchargetransition
//	wave FastScan_2D //To pass charge transition data into fitchargetransition
//	do
//		rampmultiplebd(bd6, "2", CSbias[i])
//		rampfd(fastdac, "0", -1000)
//
//		if (CSbias[i] > 49) //Set chargesensor somewhere good, (not possible with too little bias so use 50uV as minimum)
//			sc_sleep(0.1)
//			setchargesensorfd(fastdac, bd6, setpoint = 0.8/300*CSbias[i])
//		else
//			rampmultiplebd(bd6, "2", 50)
//			sc_sleep(0.1)
//			setchargesensorfd(fastdac, bd6, setpoint = 0.8/300*50)
//			rampmultiplebd(bd6, "2", CSbias[i])
//			sc_sleep(0.1)
//		endif
//
//		ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", 2001, 0, 0, "7", 4, delayy=0.1, delayx=1e-4, ramprate=100000, ADCchannels="0", xlabel="FD_SDP/50mV", setchargesensor=0)
//		fitchargetransition(FastScan_2D)
//
//		make/o/free/n=(dimsize(fitdata,0)) thetavals
//		thetavals[] = fitdata[p][2] // Is this theta??
//		ThetaVsBias[i] = mean(thetavals)
//
//		i+=1
//	while (i < numpnts(CSbias))
//end
//
//
//function VaryingSRSscanparameters()
//
//	nvar srs1, bd6, fastdac, dmm5
//
//	make/o/FREE srsT = {0.03, 	0.01, 		0.01, 		0.03, 		0.01, 		0.01, 		0.01}
//	make/o/FREE srsF = {111.11, 	111.11, 	271.11, 	271.11,	271.11,	271.11,	511.11}
//	make/o/FREE srsRO = {0,		0,			0,			0,			1,			0,			0}
//	make/o/FREE delayx = {5e-3, 	1e-3,		1e-3,		1e-3,		1e-3,		1e-4,		1e-4}
//	variable i=0
//	do
//		setsrstimeconst(srs1, srsT[i])
//		setsrsfrequency(srs1, srsF[i])
//		setsrsreadout(srs1, srsRO[i])
//		ScanFastDac2DLine(bd6, fastdac, -8500, 8500, "0", 2001, "FD_SDP/50mV", -460, -540, "13", 321, \
//						0.1, 1000, 2000, ADCchannels="02", delayx=delayx[i], rampratex=100000, x1=-8760, \
//						x2=-1380, y1=-460, y2=-500, linecut = 0, followtolerance = 0, startrange = 2000)
//		printf "Finished scan with SRStimeconst = %.3g, SRSfrequency = %.4g, SRSreadout = %d, delayx = %.2e\r", srsT[i], srsF[i], srsRO[i], delayx[i]
//		notify("Finished i = " + num2str(i) + " of 6")
//		i+=1
//	while (i<numpnts(srsT))
//
//
//end
//
//
//
//function EntropyVsFrequency([starti])
//	variable starti
//	nvar srs1, bd6, fastdac
//
////	make/o/free Frequency = 	{51.11,	111.11,	231.11, 	317, 	511.1,	17}
////	make/o/free SRSt = 			{0.1, 		0.03, 		0.03, 		0.03,	0.03,	0.3}
////	make/o/free delay = 		{0.3,		0.1,		0.1,	 	0.1	,	0.1,	1}
//	make/o/free Frequency = 	{51.11,	111.11,	159,	231.11,	317, 	317, 	511.1}//,	17}
//	make/o/free SRSt = 			{0.03, 	0.03, 		0.03,	0.03, 		0.03,	0.01,	0.01}//,	0.3}
//	make/o/free speed = 		{50, 		110,		160, 	230,		320,	320,	510}//mV/s do more pts instead of long delay
////	make/o/free delay = 		{0.1,		0.1,		0.1,	0.1,		0.1	,	0.1}//, 	0.6}
//	//make/o/n=(601, numpnts(frequency)) EvsF = NaN
//	//setscale/i x, -300, 300, EvsF
//	//setscale/I y 91.11, 91.11+60*(nr-1), EvsF
////	label left, "Frequency/Hz"
////	label bottom, "FD_SDP/50mV"
////	display; appendimage EvsF
////	wave FastScan
//	string buffer = ""
//	variable oldsrsfreq = getsrsfrequency(srs1)
//	variable oldsrstconst = getsrstimeconst(srs1)
//
//	variable i=starti
//	do
//		setsrstimeconst(srs1, SRSt[i])
//		setsrsfrequency(srs1, Frequency[i])
//		CenterOnTransition("12", fdx="0")
//		ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", round(450*2000/(1.5*speed[i])), 0, 0, "7", 50, delayy=0.5, delayx = 1e-6, ramprate=20000, ADCchannels="0123", xlabel="FD_SDP/50mV") //450Hz measure speed for all 4 channels
////		ScanFastDacRepeat(fastdac, -500, 500, "0", 501, delay[i], 10, 0.1, "FD_SDP/50mV")
//		sprintf buffer, "Finished at %.2fHz with SRSt = %.2fs and speed = %.2fmV/s\r", Frequency[i], SRSt[i], speed[i]
//		notify(buffer)
////		fd1d(fastdac, "0", -300, 300, 601, 0.3, adcchannels="02")
////		EvsF[][i] = FastScan[2*p+1]
//	//	doupdate
//		i+=1
//	while (i<numpnts(frequency))
//	setsrsfrequency(srs1, oldsrsfreq)
//	setsrstimeconst(srs1, oldsrstconst)
//end
//
//
//
//function QPCscans(fastdac, bd6)  //Used ~18th Oct 2019
//	variable fastdac, bd6
//
//	//9th Oct 19
////	make/o CSR = {-200, -250, -300, -350, -400, -450, -500}
////	make/o CStotal = {-550, -600, -650, -700, -750}
////	make/o SDP = {-200, -300, -400, -500, -600, -700}
//
//	make/o CSR = {-300}
//	make/o CSL = {-250}
////	make/o CStotal = {-550}//, -700, -750}
//	make/o SDP = {-650}
//	make/o ACG = {0}
//
//	variable i=0, j=0, k=0
//	do // Loop to change k var
//		rampmultiplebd(bd6, "3", ACG[k])
//		do	// Loop for change j var
//			rampmultiplebd(bd6, "12", SDP[j])
//			do // Loop for changing i var and running scan
//
//				rampmultiplebd(bd6, "14", CSR[i])
//				rampmultiplebd(bd6, "4", CSL[i])
//				//rampmultiplebd(bd6, "4", CStotal[0]-CSR[i])//CStotal[j]-CSR[i]) //Trying to keep charge sensor spine roughly same amount open
//				rampfd(fastdac, "1", -6000+j*500)
//				rampmultiplebd(bd6, "11", -550+j*50)
//				timsleep(1)
//				setchargesensorfd(fastdac, bd6, check=0)
//				rampmultiplebd(bd6, "11", 0)
//				rampfd(fastdac, "1", -10000)
//				timsleep(3)
//				ScanFastDac2D(bd6, fastdac, -10000, -000, "1", 2501, 0, -1100, "11", 111, ramprate=100000, ADCchannels="01", delayy=0.1, xlabel="FD_SDR/10mV")
//				printf "Finished scan at CSR = %dmV, CSL = %dmV, SDP = %dmV, ACG = %d/2mV", CSR[i], CSL[i], SDP[j], ACG[k]
//				print "\r"
//				i+=1
//			while (i < numpnts(CSR))
//			notify("Finished inner loop of (3) scans, j = "+num2str(j)+" of 4")
//			i=0
//			j+=1
//		while (j < numpnts(SDP))
//		j=0
//		k+=1
//	while (k< numpnts(ACG))
//	notify("Finished all scans")
//end
//
//
//macro calibrate_dcheat_chargesensor()
//	make/o dcheat = {200, 150, 100, 50, 30, 20, 10}
//
//	variable i=0, j=0
//	do
//		if (j == 1)
//			dcheat = dcheat*-1 // scan positive and negative to check my offset is 0
//		endif
//		do
//			rampmultiplebd(bd6, "1", dcheat[i]*10-397, ramprate=1000) //*10 to convert from uV to mV on DAC, -397 to account for offset of current amp
//			scan_transitions(bd6, dmm5, ls370, threshold=3, dcheat=dcheat[i])
////			CorrectChargeSensor(bd6, dmm5, i=i, check=0, dcheat=dcheat[i])
////			sc_sleep(10.0)
////			scanbabydacrepeat(bd6, -30, +30, "3", round(60/0.152/1), 0.01, 1000, 10, 0.05)
//			print "Finished at DC heat of "+num2str(dcheat[i])+"uV, DAC1 = "+num2str(dcheat[i]*10-397)+"mV. Scan "+num2str(i+1+j*numpnts(dcheat))+" out of "+num2str(numpnts(dcheat)*2)
//			getslacknotice("U8W2V6QK0", message="Finished scan "+num2str(i+1+j*numpnts(dcheat))+" out of "+num2str(numpnts(dcheat)*1),min_time=1)
//			i+=1
//		while (i<numpnts(dcheat))
//		i=0
//		j+=1
//	while (j<1)
//end
//
//macro calibrate_theta()
//
//	make/o targettemps =  {25, 50, 75, 100, 112.5, 125, 137.5, 150, 162.5, 175, 187.5, 200}
//	make/o heaterranges = {1, 1, 1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1}
//
////	make/o targettemps =  {200, 175, 150, 125, 100, 75, 50, 25}
////	make/o heaterranges = {3.1, 3.1, 3.1, 3.1, 3.1, 1, 1, 0.31}
//	setLS370exclusivereader(ls370,"bfsmall_mc")
////	setLS370PIDcontrol(ls370,6,200,10)  // speed up getting to 200mK
////	sc_sleep(60.0)
//	print "turning off AC heat"
//	setsrsamplitude(srs1, 0)
//
//	if (numpnts(targettemps) != numpnts(heaterranges)) // sanity check
//		abort "Different number of target temps to heaterranges"
//	endif
//
//	scan_transitions(bd6, dmm5, ls370, threshold=1)
//	print "Finished at base temp"
//	print getLS370temp(ls370, "mc")
//
//	variable i=0
//	do
//		setLS370PIDcontrol(ls370,6,targettemps[i],heaterranges[i])
//		sc_sleep(2.0)
//		WaitTillTempStable(ls370, targettemps[i], 5, 20, 0.10)
//		sc_sleep(60.0)
//		print "MEASURE AT: "+num2str(targettemps[i])+"mK"
//		scan_transitions(bd6, dmm5, ls370, threshold=1)
//		i+=1
//	while ( i<numpnts(targettemps) )
//	// kill temperature control
//
////	turnoffLS370MCheater(ls370)
////	resetLS370exclusivereader(ls370)
////	sc_sleep(60*90)
////	scan_transitions(bd6, dmm5, ls370, threshold=1)
//end
//
//
//function ThetaVsHQPCbias_NoBiasRepeats(temperature) // Just need to set up on a transition first and hope it stays there
//	variable temperature
//	nvar bd6, fastdac, srs1
//	string buffer = ""
//
//
//	make/o CSbias = {100, 200, 300, 500, 750, 1000} //biases go through 1000 divider. CA0 set to offset it's own bias.
//	variable i=0
//
//	rampmultiplebd(bd6, "2", 0) //
//	setoffsetfd("0", "0", check=0) // reset CA0 offset for CS
//
//	setsrsamplitude(srs1, 0) // Turn off HQPC heat
//	rampmultiplebd(bd6, "3", 0) //
//
//	wave fd_0adc //For centering SDR
//	wave/t old_dacvalstr
//	variable newSDR, oldSDR
//	do  //No bias repeats to get accurate theta vs fridge temp
//
//		rampmultiplebd(bd6, "2", CSbias[i])
//		oldSDR = str2num(old_dacvalstr[13])
//		rampfd(fastdac, "0", 0)
//		CenterOnTransition("13", fdx="0")
//
//		rampfd(fastdac, "0", -1000)
//		setchargesensorfd(fastdac, bd6, setpoint = CSbias[i]/300*0.8)
//		ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", 2001, 0, 0, "7", 50, ADCchannels="0", xlabel="FD_SDP/1000mV", ramprate=100000, delayx=3e-3, delayy=0.1)
//		printf "Finished no heat repeat scan with CSbias = %duV and delay = 1e-3\r", CSbias[i]
//		i+=1
//	while (i<numpnts(CSbias))
//
//
//
//	rampmultiplebd(bd6, "2", 500)
//	rampfd(fastdac, "0", -1000)
//	setchargesensorfd(fastdac, bd6, setpoint = 500/300*0.8)
//
//	oldSDR = str2num(old_dacvalstr[13])
//	rampfd(fastdac, "0", 0)
//	ScanBabyDAC(bd6, -480-20, -480+20, "13", 401, 0.001, 1000, nosave=1)
//	newSDR = FindTransitionMid(fd_0adc)
//	if (numtype(newSDR) == 0 && newSDR > -500 && newSDR < -400) // If reasonable then center there
//		rampmultiplebd(bd6, "13", newSDR)
//	else
//		rampmultiplebd(bd6, "13", oldSDR)
//	endif
//
//	rampfd(fastdac, "0", -1000)
//	setchargesensorfd(fastdac, bd6, setpoint = 500/300*0.8)
//	ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", 2001, -500, 500, "3", 501, ADCchannels="0", xlabel="FD_SDP/1000mV", ramprate=100000, delayx=1e-6, delayy=0.1)
//	sprintf buffer, "Finished HQPC_DCbias scan at %dmK with CSbias = 500uV\r", temperature
//	notify(buffer)
//end
//
//function steptempscanSomething()
//	nvar bd6, srs1
//	svar ls370
//
//	make/o targettemps =  {300, 275, 250, 225, 200, 175, 150, 125, 100, 75, 50, 40, 30, 20}
//	make/o heaterranges = {10, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 3.1, 1, 1, 1, 1}
//	setLS370exclusivereader(ls370,"bfsmall_mc")
//
//
//	variable i=0
//	do
//		setLS370PIDcontrol(ls370,6,targettemps[i],heaterranges[i])
//		sc_sleep(2.0)
//		WaitTillTempStable(ls370, targettemps[i], 5, 20, 0.10)
//		sc_sleep(60.0)
//		print "MEASURE AT: "+num2str(targettemps[i])+"mK"
////		notify( "MEASURE AT: "+num2str(targettemps[i])+"mK")
//		ThetaVsHQPCbias_NoBiasRepeats(targettemps[i])
//
//		//Scan Here
//
//		i+=1
//	while ( i<numpnts(targettemps) )
//
//	// kill temperature control
//	turnoffLS370MCheater(ls370)
//	resetLS370exclusivereader(ls370)
//	sc_sleep(60.0*30)
//	ThetaVsHQPCbias_NoBiasRepeats(targettemps[i])
//
//
//// 	ScanHere for base temp
//
//end
//
//function steptempscanSomething2()
//	nvar bd6, srs1, fastdac
//	svar ls370
//
//	make/o targettemps =  	{300, 250, 200, 150, 100, 50}
//	make/o heaterranges = 	{10, 3.1, 3.1, 3.1, 3.1, 1}
//	make/o SRSout = 		  	{36, 33, 27, 21, 18, 7} //nA *50 to get mV
//
//	setLS370exclusivereader(ls370,"bfsmall_mc")
//
//	string buffer
//	wave/t old_dacvalstr
//	variable i=0, j=0
//	do
//		setLS370PIDcontrol(ls370,6,targettemps[i],heaterranges[i])
//		sc_sleep(2.0)
//		WaitTillTempStable(ls370, targettemps[i], 5, 20, 0.10)
//		sc_sleep(60.0)
//		print "MEASURE AT: "+num2str(targettemps[i])+"mK"
//
//
//
//		make/o/free Var1 = {1797, 2825, 2826, 2827}
//		make/o/t/free var1a = {"0->1", "1->2", "2->3", "3->4"}
//		j=0
//		sprintf buffer, "Starting scans of 0 -> 4 transition at zero field fridge temp = %.1fmK ================================================================================================================================", getls370temp(ls370, "mc")*1000
//		notify(buffer)
//		do // Loop for changing i var1 and running scan
//			loaddacs(var1[j], noask=1)
//			SetupStandardEntropy(printchanges=1, keepphase=1)
//			setsrsamplitude(srs1, SRSout[j]*50)
//			centerontransition("12", fdx="0")
//			sprintf buffer, "Starting scan at high field at loaddacs = %d, which is %s transition with SRSout=%.1fmV AC heat\r", Var1[j], var1a[j], SRSout[i]*50
//			print buffer
//			ScanFastDac2D(bd6, fastdac, -2000, 2000, "0", 12001, 0, 0, "7", 30, ADCchannels="0123", xlabel="FD_SDP/50mV", ramprate=100000, delayx=1e-6, delayy=0.1, printramptimes=0)
//			j+=1
//		while (j < numpnts(Var1))
//
//		setsrsamplitude(srs1, 0)
//		sprintf buffer, "Starting DC bias at temp = %.1fmK, HQPC = %smV", getls370temp(ls370, "mc")*1000, old_dacvalstr[15]
//		notify(buffer)
//		ScanFastDac2D(bd6, fastdac, -1000, 1000, "0", 1001, -500, 500, "3", 1001, ADCchannels="0", xlabel="FD_SDP/1000mV", ramprate=100000, delayx=1e-6, delayy=0.1, printramptimes=0)
//
//		i+=1
//	while ( i<numpnts(targettemps) )
//
//	// kill temperature control
//	//turnoffLS370MCheater(ls370)
//	resetLS370exclusivereader(ls370)
//
//
//// 	ScanHere for base temp
//
//end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Other Functions///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAOtherFunctions()
end

function udh5()

	string infile = wavelist("*",";","") // get wave list
	string hdflist = indexedfile(data,-1,".h5") // get list of .h5 files

	string currentHDF="", currentWav="", datasets="", currentDS
	variable numHDF = itemsinlist(hdflist), fileid=0, numWN = 0, wnExists=0

	variable i=0, j=0, numloaded=0

	for(i=0; i<numHDF; i+=1) // loop over h5 filelist

	   currentHDF = StringFromList(i,hdflist)

		HDF5OpenFile/P=data /R fileID as currentHDF
		HDF5ListGroup /TYPE=2 /R=1 fileID, "/" // list datasets in root group
		datasets = S_HDF5ListGroup
		numWN = itemsinlist(datasets)
		currentHDF = currentHDF[0,(strlen(currentHDF)-4)]
		for(j=0; j<numWN; j+=1) // loop over datasets within h5 file
			currentDS = StringFromList(j,datasets)
			currentWav = currentHDF+currentDS
		   wnExists = FindListItem(currentWav, infile,  ";")
		   if (wnExists==-1)
		   	// load wave from hdf
		   	HDF5LoadData /Q /IGOR=-1 /N=$currentWav fileID, currentDS
		   	numloaded+=1
		   endif
		endfor
		HDF5CloseFile fileID
	endfor

   print numloaded, "waves uploaded"
end



function notify(message)
	string message
	print message
	getslacknotice("U8W2V6QK0", message=message,min_time=1) //Me
//	getslacknotice("UFTMDFVTR", message=message,min_time=1) //Owen? Or other way around??
end


function timsleep(s)
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
// TODO: Make this again
//function noisemeasurement(fastdac, num)
//	variable fastdac, num
//	variable i=0
//	wave fastscan
//	variable ret = 1
//	do
//		ret = clearbuffer(fastdac)
//	while (ret!=0)
//
//	for (i=0; i < num; i += 1)
//		FD1D(fastdac, "0", 0, 0, 3000, 1e-3);
//		SetScale/I x 0,3*1.459,"", FastScan;
//		DSPPeriodogram/q/DBR=1000/DTRD/WIN=Hamming/SEGN={1000,0}/DEST=W_Periodogram FastScan
//		doupdate
//	endfor
//end



Function CheckInstrIds(bd6, fastdac, srs1, srs2, srs4, dmm5, magz, magy) //TODO: Make this not fail if instruments are missing. Also should probably just look for global variables
	variable bd6, fastdac, srs1, srs2, srs4, dmm5, magz, magy
	//Check no instruments have same number
	make/o instrids = {bd6, fastdac, srs1, srs2, srs4, dmm5, magz, magy}
	FindDuplicates/DN=instrdups instrids  // Creates wave instrdups with all duplicated id values
	if (numpnts(instrdups) > 0)
		getslacknotice("U8W2V6QK0", message="Stupid computer has assigned more than one instrument the same ID again!",min_time=1)
		abort "Instrument id's are not unique, look at wave instrdups for list"
	endif
end


function makecolorful([rev, nlines])
	variable rev, nlines
	variable num=0, index=0,colorindex
	string tracename
	string list=tracenamelist("",";",1)
	colortab2wave rainbow
	wave M_colors
	variable n=dimsize(M_colors,0), group
	do
		tracename=stringfromlist(index, list)
		if(strlen(tracename)==0)
			break
		endif
		index+=1
	while(1)
	num=index-1
	if( !ParamIsDefault(nlines))
		group=index/nlines
	endif
	index=0
	do
		tracename=stringfromlist(index, list)
		if( ParamIsDefault(nlines))
			if( ParamIsDefault(rev))
				colorindex=round(n*index/num)
			else
				colorindex=round(n*(num-index)/num)
			endif
		else
			if( ParamIsDefault(rev))
				colorindex=round(n*ceil((index+1)/nlines)/group)
			else
				colorindex=round(n*(group-ceil((index+1)/nlines))/group)
			endif
		endif
		ModifyGraph rgb($tracename)=(M_colors[colorindex][0],M_colors[colorindex][1],M_colors[colorindex][2])
		index+=1
	while(index<=num)

end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////// BabyDac /////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AABabyDac()
end


Window dacloadwindow() : Panel
	PauseUpdate; Silent 1 // building window
	NewPanel /W=(100,100,400,630) // window size
	ModifyPanel frameStyle=2
	SetDrawLayer UserBack
	SetDrawEnv fsize= 25,fstyle= 1
	DrawText 20, 45,"Choose DAC init" // Headline
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 40,80,"Old init"
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 170,80,"Loaded"
	ListBox loadlist,pos={10,90},size={280,390},fsize=16,frame=2
	ListBox loadlist,fStyle=1,listWave=root:initwave,selWave=root:attinitlist,mode= 0
	Button old_dacinit,pos={40,490},size={70,20},proc=bdAskUserUpdate,title="OLD INIT" // 12th Mar keep changing fom here
	Button default_dacinit,pos={170,490},size={70,20},proc=bdAskUserUpdate,title="DEFAULT"
EndMacro

// TODO: Make this work with FastDacs
function LoadDacs(datnum, [noask])
	variable datnum, noask
	variable fileid, i, output, check

	HDF5OpenFile /P=data fileid as "dat"+num2str(datnum)+".h5"

	HDF5Loaddata/o/Q /N=loadeddacvalstr 	fileid, "dacvalstr"
	HDF5Loaddata/O/Q /N=loaddedfdacvalstr 	fileid, "fdacvalstr"

	HDF5CloseFile fileid


	wave/t loadeddacvalstr
	wave/t loadedfdacvalstr
	wave/t old_dacvalstr
	wave/t	old_fdacvalstr
	wave/t dacvalstr
	wave/t fdacvalstr
	variable/g bd_answer = 0
	variable/g fd_answer = 0

	if (noask == 0)
		make /o attinitlist = {{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}
		make /o/t/n=(16,2) initwave
		initwave[0,15][1] = loadeddacvalstr[p][1]
		initwave[0,15][0] = old_dacvalstr[p]
		execute("bdInitWindow()")
		PauseForUser bdInitWindow  //Sets bd_answer to -1 for change, or 1 for don't change
		// Just used same init window here because I didn't want to make a new one.
	endif



	if (bd_answer == -1 || noask == 1)
		// open temporary connection to babyDAC
		dacvalstr[][3] = loadeddacvalstr[p][3]
		svar bd_controller_addr
		openBabyDACconnection("bd_window_resource", bd_controller_addr, verbose=0)
		nvar bd_window_resource
		for(i=0;i<16;i+=1)
			if(str2num(loadeddacvalstr[i][1]) != str2num(old_dacvalstr[i]))
				output = str2num(loadeddacvalstr[i][1])
				check = rampOutputBD(bd_window_resource, i, output)
				if(check == 1)
					dacvalstr[i][1] = loadeddacvalstr[i][1]
					old_dacvalstr[i] = dacvalstr[i][1]
				else
					dacvalstr[i][1] = old_dacvalstr[i]
				endif
			endif
		endfor
		viClose(bd_window_resource) // close VISA resource
	else
		print "User decided not to load dac values"
	endif


end


function/S GetLabel(channels, [fastdac])
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




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////// Fastdac /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAFastdac()
end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////// Temperature //////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AATemperature()
end

function TimWaitTillTempStable(instrID, targetTmK, times, delay, err)
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
			currentT += getLS370temp(instrID, "mc")/10 // do some averaging
			sc_sleep(0.2)
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



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////// VIRTUAL GATES ////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAVirtualGates()
end
// OLD VIRTUAL GATES///////////////////////
//function define_virtual_gate_origin()
//	// this function defines the virtual gate origin in a wave
//	make /o virtual_gate_origin = {48,1170,0,0,0,-238,-630,-510,-2198,-630,-630,-400,-3972,-460,-400,-1100}
//end
//
//function define_virtual_gate_couplings()
//	// this function defines the virtual gate couplings
//	make /o virtual_gate_couplings = {{1,0.7605,0,0},{0.08998,0.9912,0,0},{3.8830,6.1527,1,0},{3.9904,1.4254,0,1}}
//	matrixop /o inv_gate_couplings = inv(virtual_gate_couplings)
//end
///////////////////////////////////////


function define_virtual_gate_origin()
	// this function defines the virtual gate origin in a wave
	make /o virtual_gate_origin = {0,1150,0,-25,0,-238,-630,-510,-2190,-630,-630,-275,-4091,-390,-400,-995}
end

function define_virtual_gate_couplings()
	// this function defines the virtual gate couplings
	make /o virtual_gate_couplings = {{0.981,0.681,0,0},{0.133,0.936,0,0},{3.938,7.419,1,0},{3.69,1.32,0,1}}
	matrixop /o inv_gate_couplings = inv(virtual_gate_couplings)
end

//ScanVirtualGates2D(bd6, -8, 10, "VP1", 181, 0.3, -5, 5, "VP1", 3, 1.0, vp2=4)

function reset_gates_to_origin(instrID)
	// resets all the gates to the point from which the virtual gates are defined
	// only changes DAC5-14
	// channels 0-4 are biases and unused channels
	// channel 15 controls the heater QPC and should have a minimal coupling to the dots
	variable instrID
	define_virtual_gate_origin()
	wave vgo = virtual_gate_origin

	variable i=0
	for(i=5;i<15;i+=1)
		RampOutputBD(instrID, i, vgo[i])
	endfor
end


function RampVirtualGates(instrID, GateKeyString)
	// example GateKeyString = "VP1:0;VP2:0;VG1:0;VG2:0"
	// vp_small and vp_big are deltas
	// both virtual gates are equal to zero at the virtual gate origin
	variable instrID
	String GateKeyString

	variable vp_small, vp_big, vg_coup, vg_res

	vp_small = NumberByKey("VP1", GateKeyString)
	vp_big = NumberByKey("VP2", GateKeyString)
	vg_coup = NumberByKey("VG1", GateKeyString)
	vg_res = NumberByKey("VG2", GateKeyString)

	if(numtype(vp_small)!=0 || numtype(vp_big)!=0 || numtype(vg_coup)!=0 || numtype(vg_res)!=0)
		print GateKeyString
		abort("Incorrect format for GateKeyString. Should be e.g. 'VP1:0;VP2:0;VG1:0;VG2:0'")
	endif

	wave vgo = virtual_gate_origin
	wave igc = inv_gate_couplings
	make /o vg_deltas = {vp_small, vp_big, vg_coup, vg_res}
	MatrixOP /o gate_deltas = igc x vg_deltas


//	print vgo[12]+gate_deltas[0], vgo[8]+gate_deltas[1], vgo[11]+gate_deltas[2], vgo[13]+gate_deltas[3]

	RampOutputBD(instrID, 12, vgo[12]+gate_deltas[0], ramprate=1000)
//	sc_sleep(0.01)
	RampOutputBD(instrID, 8, vgo[8]+gate_deltas[1], ramprate=1000)
//	sc_sleep(0.01)
	RampOutputBD(instrID, 11, vgo[11]+gate_deltas[2], ramprate=1000)
//	sc_sleep(0.01)
	RampOutputBD(instrID, 13, vgo[13]+gate_deltas[3], ramprate=1000)
//	sc_sleep(0.01)

end

function checkgatevalid(gate)
	string gate
	string gatelist="VP1;VP2;VG1;VG2"
	int i=0

	for (i=0; i<4; i+=1)
		if (cmpstr(gate, stringfromlist(i, gatelist))==0)
			return 1
		endif
	endfor
	abort("One of the Gate choices was invalid")
end

function ScanVirtualGates2D(instrID, startx, finx, xgate, numptsx, delayx, starty, finy, ygate, numptsy, delayy, [vp1, vp2, vg1, vg2,comments]) //Units: mV
	// Coupling between dots in x
	// small dot transitions in y

	variable instrID, startx, finx, numptsx, delayx, starty, finy, numptsy, delayy, vp1, vp2, vg1, vg2
	string xgate, ygate, comments
	variable i=0, j=0, setpointx, setpointy
	string x_label="", y_label="", GKS="" //GateKeyString

	checkgatevalid(xgate)
	checkgatevalid(ygate)


	if (cmpstr(xgate, ygate) == 0)
		abort("x and y gates were equal")
	endif


	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")==0 || cmpstr(ygate, "VP1")==0)
		abort("optional gate same as x or y gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")==0 || cmpstr(ygate, "VP2")==0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")==0 || cmpstr(ygate, "VG1")==0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")==0 || cmpstr(ygate, "VG2")==0)
		abort("optional gate same as x or y gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx
	setpointy = starty
	GKS = replaceNumberByKey(xgate, GKS, setpointx)
	GKS = replacenumberByKey(ygate, GKS, setpointy)


	sprintf x_label, xgate
	sprintf y_label, ygate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

	// main loop
	do
		setpointx = startx
		setpointy = starty + (i*(finy-starty)/(numptsy-1))
		GKS = replaceNumberByKey(xgate, GKS, setpointx)
		GKS = replacenumberByKey(ygate, GKS, setpointy)
		RampVirtualGates(instrID, GKS)
		sc_sleep(delayy)
		j=0
		do
		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
		  GKS = replacenumberByKey(xgate, GKS, setpointx)
		  RampVirtualGates(instrID, GKS)
		  sc_sleep(delayx)
		  RecordValues(i, j)
		  j+=1
		while (j<numptsx)
		i+=1
	while (i<numptsy)
	SaveWaves(msg=comments)
end

function ScanVirtualGate(instrID, startx, finx, xgate, numptsx, delayx, [vp1, vp2, vg1, vg2,comments]) //Units: mV

	variable instrID, startx, finx, numptsx, delayx, vp1, vp2, vg1, vg2
	string xgate, comments
	variable j=0, setpointx
	string x_label="", GKS="" //GateKeyString

	checkgatevalid(xgate)


	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")==0)
		abort("optional gate same as x gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")==0)
		abort("optional gate same as x gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx
	GKS = replaceNumberByKey(xgate, GKS, setpointx)


	sprintf x_label, xgate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, x_label=x_label)

	// main loop

	do
	  setpointx = startx + (j*(finx-startx)/(numptsx-1))
	  GKS = replacenumberByKey(xgate, GKS, setpointx)
	  RampVirtualGates(instrID, GKS)
	  sc_sleep(delayx)
	  RecordValues(j,0)
	  j+=1
	while (j<numptsx)
	SaveWaves(msg=comments)
end

function ScanVirtualGateRepeat(instrID, startx, finx, xgate, numptsx, delayx, numptsy, delayy, [vp1, vp2, vg1, vg2,comments]) //Units: mV
	// Coupling between dots in x
	// small dot transitions in y

	variable instrID, startx, finx, numptsx, delayx, numptsy, delayy, vp1, vp2, vg1, vg2
	string xgate, comments
	variable i=0, j=0, setpointx, starty=1, finy=numptsy
	string x_label="", y_label="Repeats", GKS="" //GateKeyString

	checkgatevalid(xgate)

	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")==0)
		abort("optional gate same as x gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")==0)
		abort("optional gate same as x gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")==0)
		abort("optional gate same as x gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx

	GKS = replaceNumberByKey(xgate, GKS, setpointx)



	sprintf x_label, xgate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

	// main loop
	do
		setpointx = startx
		GKS = replaceNumberByKey(xgate, GKS, setpointx)
		RampVirtualGates(instrID, GKS)
		sc_sleep(delayy)
		j=0
		do
		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
		  GKS = replacenumberByKey(xgate, GKS, setpointx)
		  RampVirtualGates(instrID, GKS)
		  sc_sleep(delayx)
		  RecordValues(i, j)
		  j+=1
		while (j<numptsx)
		i+=1
	while (i<numptsy)
	SaveWaves(msg=comments)
end


function cutFunc(xval, yval)
	// this function is a template needed for the scan function defined below
	variable xval,yval
end

function ScanVirtualGates2Dcut(instrID, startx, finx, xgate, numptsx, delayx, starty, finy, ygate, numptsy, delayy, func, [vp1, vp2, vg1, vg2,comments]) //Units: mV
	// Coupling between dots in x
	// small dot transitions in y

	variable instrID, startx, finx, numptsx, delayx, starty, finy, numptsy, delayy, vp1, vp2, vg1, vg2
	string xgate, ygate, func, comments
	variable i=0, j=0, setpointx, setpointy
	string x_label="", y_label="", GKS="" //GateKeyString

	FUNCREF cutFunc fcheck=$func

	checkgatevalid(xgate)
	checkgatevalid(ygate)


	if (cmpstr(xgate, ygate) == 0)
		abort("x and y gates were equal")
	endif


	if(paramisdefault(comments))
		comments=""
	endif

  	if(ParamIsDefault(vp1))
		vp1=0
	elseif (cmpstr(xgate, "VP1")!=0 || cmpstr(ygate, "VP1")!=0)
		abort("optional gate same as x or y gate")
	endif
  	if(ParamIsDefault(vp2))
		vp2=0
	elseif (cmpstr(xgate, "VP2")!=0 || cmpstr(ygate, "VP2")!=0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg1))
		vg1=0
	elseif (cmpstr(xgate, "VG1")!=0 || cmpstr(ygate, "VG1")!=0)
		abort("optional gate same as x or y gate")
	endif
	if(ParamIsDefault(vg2))
		vg2=0
	elseif (cmpstr(xgate, "VG2")!=0 || cmpstr(ygate, "VG2")!=0)
		abort("optional gate same as x or y gate")
	endif

	GKS = replaceNumberByKey("VP1", GKS, vp1)
	GKS = replaceNumberByKey("VP2", GKS, vp2)
	GKS = replaceNumberByKey("VG1", GKS, vg1)
	GKS = replaceNumberByKey("VG2", GKS, vg2)

	setpointx = startx
	setpointy = starty
	GKS = replaceNumberByKey(xgate, GKS, setpointx)
	GKS = replacenumberByKey(ygate, GKS, setpointy)


	sprintf x_label, xgate
	sprintf y_label, ygate

	// set starting values
	define_virtual_gate_origin()
	define_virtual_gate_couplings()

	RampVirtualGates(instrID, GKS)
	sc_sleep(4.0)

	// initialize waves
	InitializeWaves(startx, finx, numptsx, starty=starty, finy=finy, numptsy=numptsy, x_label=x_label, y_label=y_label)

	// main loop
	do
		j=0
		setpointx = startx
		setpointy = starty + (i*(finy-starty)/(numptsy-1))

		do
			setpointx = startx + (j*(finx-startx)/(numptsx-1))
			if( fcheck(setpointx, setpointy) == 0 && j<numptsx)
				RecordValues(i, j, fillnan=1)
				j+=1
			else
				break
			endif
		while( 1 )

		if (j == numptsx)
			i+=1
			continue
		endif

		GKS = replacenumberByKey(ygate, GKS, setpointy)
	   GKS = replacenumberByKey(xgate, GKS, setpointx)
	   RampVirtualGates(instrID, GKS)
		sc_sleep(delayy)

		do
		  setpointx = startx + (j*(finx-startx)/(numptsx-1))
		  if( fcheck(setpointx, setpointy) == 0 )
		     RecordValues(i, j, fillnan=1)
		  else
		     GKS = replacenumberByKey(xgate, GKS, setpointx)
		     RampVirtualGates(instrID, GKS)
		     sc_sleep(delayx)
		     RecordValues(i, j)
		  endif
		  j+=1
		while (j<numptsx)

		i+=1
	while (i<numptsy)
	SaveWaves(msg=comments)
end
