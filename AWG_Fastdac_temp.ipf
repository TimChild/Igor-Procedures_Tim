

function fdAWG_add_wave(instrID, wave_num, add_wave)
	// Adds to the AWGs stored in the fastdac
	variable instrID
	variable wave_num  	// Which AWG to add to (currently allowed 0 or 1)
	wave add_wave		// add_wave should be 2D with add_wave[0] = mV setpoint for each step in wave
					   		// 									 add_wave[1] = how many samples to stay at each setpoint

	// assert add_wave is 2D and has no nans/blanks
	// assert wave_num = 0,1

	// get fd_address from instrID

	// convert to string in form "ADD_WAVE,<wave_num>,<sp0>,<#sp0>,...,<spn>,<#spn>"
	// check len < 128/256/512 characters  (size of buffer input to fd)
		// if not then split into necessary chunks

	// send command(s)

	// check response(s) ("WAVE,<wave_num>,<len_setpoints>")

	// add to wave fdAWG<wave_num> (2D of setpoints and sample times)

end


function fdAWG_clear_wave(instrID, wave_num)
	// Clears AWG# from the fastdac and the corresponding global wave in IGOR
	variable instrID
	variable wave_num // Which AWG to clear (currently allowed 0 or 1)

	// assert wave_num = 0,1

	// get fd_address...

	string cmd
	sprintf cmd, "CLR_WAVE,%d", wave_num
	//send command

	//check response == "WAVE,<wave_num>,0"

end


function fdAWG_record_values(instrID, ...)

  // compare to earlier call of InitializeWaves
  fdRV_check_init()

end






function fdRV_check_init()
  nvar fastdac_init
  if(fastdac_init != 1)
    print("[ERROR] \"RecordValues\": Trying to record fastDACs, but they weren't initialized by \"InitializeWaves\"")
    abort
  endif
end

function fdRV_set_scanList(scanList, rampCh, start, fin)
  struct fdacChLists &scanList  // alters passed struct
  string rampCh, start, fin

  variable dev_adc=0
	dev_adc = sc_fdacSortChannels(scanlist,rampCh,start,fin)

	string err = ""
	// check that the number of dac channels equals the number of start and end values
	if(itemsinlist(scanlist.daclist,",") != itemsinlist(scanlist.startval,",") || itemsinlist(scanlist.daclist,",") != itemsinlist(scanlist.finval,","))
		print("The number of DAC channels must be equal to the number of starting and ending values!")
		sprintf err, "Number of DAC Channel = %d, number of starting values = %d & number of ending values = %d", itemsinlist(scanlist.daclist,","), itemsinlist(scanlist.startval,","), itemsinlist(scanlist.finval,",")
		print err
		abort
	endif
end


function fdRV_check_ramprates(measFreq, numpts rampCh, scanList)
  // check if effective ramprate is higher than software limits
  variable measFreq, numpts
  string rampCh
  struct fdacChLists scanList

  svar fdacvalstr
  svar activegraphs

  variable eff_ramprate, answer, i, k, channel
  string question
  for(i=0;i<itemsinlist(rampCh,",");i+=1)
    eff_ramprate = abs(str2num(stringfromlist(i,scanlist.startval,","))-str2num(stringfromlist(i,scanlist.finval,",")))*(measureFreq/numpts)
    channel = str2num(stringfromlist(i, rampCh, ","))
    if(eff_ramprate > str2num(fdacvalstr[channel][4])*1.05)  // Allow 5% too high for convenience
      // we are going too fast
      sprintf question, "DAC channel %d will be ramped at %.1f mV/s, software limit is set to %s mV/s. Continue?", channel, eff_ramprate, fdacvalstr[channel][4]
      answer = ask_user(question, type=1)
      if(answer == 2)
        print("[ERROR] \"RecordValues\": User abort!")
        dowindow/k SweepControl // kill scan control window
        for(k=0;k<itemsinlist(activegraphs,";");k+=1)
          dowindow/k $stringfromlist(k,activegraphs,";")
        endfor
        abort
      endif
    endif
  endfor
end

function fdRV_check_lims(scanList)
  // check that start and end values are within software limits
  struct fdacChLists scanList

  svar fdacvalstr

  variable answer, i, k
  string softLimitPositive = "", softLimitNegative = "", expr = "(-?[[:digit:]]+),([[:digit:]]+)"
  variable startval = 0, finval = 0
  for(i=0;i<itemsinlist(scanlist.daclist,",");i+=1)
    splitstring/e=(expr) fdacvalstr[str2num(stringfromlist(i,scanlist.daclist,","))][2], softLimitNegative, softLimitPositive
    startval = str2num(stringfromlist(i,scanlist.startval,","))
    finval = str2num(stringfromlist(i,scanlist.finval,","))
    if(startval < str2num(softLimitNegative) || startval > str2num(softLimitPositive) || finval < str2num(softLimitNegative) || finval > str2num(softLimitPositive))
      // we are outside limits
      sprintf question, "DAC channel %s will be ramped outside software limits. Continue?", stringfromlist(i,scanlist.daclist,",")
      answer = ask_user(question, type=1)
      if(answer == 2)
        print("[ERROR] \"RecordValues\": User abort!")
        dowindow/k SweepControl // kill scan control window
        for(k=0;k<itemsinlist(activegraphs,";");k+=1)
          dowindow/k $stringfromlist(k,activegraphs,";")
        endfor
        abort
      endif
    endif
  endfor
end


function fdRV_ramp_start(instrID, scanList, ramprate)
  // move DAC channels to starting point
  struct fdacChLists scanList
  variable instrID, ramprate

  variable i
  for(i=0;i<itemsinlist(scanList.daclist,",");i+=1)
    rampOutputfdac(instrID,str2num(stringfromlist(i,scanList.daclist,",")),str2num(stringfromlist(i,scanList.startVal,",")),ramprate=ramprate)
  endfor
end


function fdRV_start_INT_RAMP(instrID, scanList, numpts)
  // build command and start ramp
  // for now we only have to send one command to one device.
  struct fdacChLists scanList
  variable instrID, numpts

  string cmd = "", dacs="", adcs=""
  dacs = replacestring(",",scanlist.daclist,"")
  adcs = replacestring(",",scanlist.adclist,"")
  // OPERATION, DAC CHANNELS, ADC CHANNELS, INITIAL VOLTAGES, FINAL VOLTAGES, # OF STEPS
  sprintf cmd, "INT_RAMP,%s,%s,%s,%s,%d\r", dacs, adcs, scanList.startVal, scanList.finVal, numpts
  writeInstr(instrID,cmd)
end


function fdRV_get_read_chunk_size(numADCs, numpts, measFreq, totalByteReturn)
  // Returns the size of chunks that should be read at a time
  variable numADCs, numpts, measFreq, totalByteReturn

  variable read_chunk=0, bytesSec = roundNum(2*measFreq*numADCs,0)
  variable chunksize = roundNum(numADCs*bytesSec/50,0) - mod(roundNum(numADCs*bytesSec/50,0),numADCs*2)
  if(chunksize < 50)
    chunksize = 50 - mod(50,numADCs*2) // 50 or 48 //This will fail for 7ADCs
  endif
  if(totalByteReturn > chunksize)
    read_chunk = chunksize
  else
    read_chunk = totalByteReturn
  endif
  return read_chunk
end

function fdRV_update_graphs()
  // updates activegraphs which takes about 15ms
  svar activegraphs

  variable i, errCode = 0
  for(i=0;i<itemsinlist(activegraphs,";");i+=1)
    doupdate/w=$stringfromlist(i,activegraphs,";")
  endfor
end

function fdRV_check_sweepstate()
  // if abort button pressed then stops FDAC sweep then aborts
  try
    sc_checksweepstate(fastdac=1)
  catch
    errCode = GetRTError(1)
    stopFDACsweep(instrID)
    if(v_abortcode == -1)
			sc_abortsweep = 0
			sc_pause = 0
		endif
    abortonvalue 1,10
  endtry
end


function fdRV_read_chunk(instrID, read_chunk, buffer)
  variable instrID, read_chunk
  string &buffer
  buffer = readInstr(instrID, read_bytes=read_chunk, binary=1)
  // If failed, abort
  if (cmpstr(buffer, "NaN") == 0)
    stopFDACsweep(instrID)
    abort
  endif
end


function fdRV_distribute_data(buffer, scanList, bytes_read, totalByteReturn, numADCs, read_chunk, rowNum, direction)
  // add data to rawwaves and datawaves
  struct fdacChLists scanList
  string &buffer  // Passing by reference for speed of execution
  variable bytes_read, totalByteReturn, numADCs, read_chunk, rowNum, direction

  variable col_num_start
  if (direction == 1)
    col_num_start = bytes_read/(2*numADCs)
  elseif (direction == -1)
    col_num_start = (totalByteReturn-bytes_read)/(2*numADCs)-1
  endif
  sc_distribute_data(buffer,scanList.adclist,read_chunk,rowNum,col_num_start, direction=direction)
end


function fdRV_update_window(instrID, scanList)
  struct fdacChLists scanList
  variable instrID

  svar fdacvalstr

  variable i, channel
  for(i=0;i<itemsinlist(scanlist.daclist,",");i+=1)
    channel = str2num(stringfromlist(i,scanlist.daclist,","))
    fdacvalstr[channel][1] = stringfromlist(i,scanlist.finval,",")
    updatefdacWindow(channel)
  endfor
  for(i=0;i<numADCs;i+=1)
    channel = str2num(stringfromlist(i,scanlist.adclist,","))
    getfadcChannel(instrID,channel)
  endfor
end


function fdRV_process_set_cutoff(RCCutoff, cutoff_frac, notch_fracList)
  variable RCCutoff, &cutoff_frac
  string &notch_fracList

  string warn = "", notch_fracList = ""
  variable doLowpass=0,cutoff_frac=0
  if(RCCutoff != 0)
    // add lowpass filter
    doLowpass = 1
    cutoff_frac = RCcutoff/measureFreq
    if(cutoff_frac > 0.5)
      print("[WARNING] \"fdacRecordValues\": RC cutoff frequency must be lower than half the measuring frequency!")
      sprintf warn, "Setting it to %.2f", 0.5*measureFreq
      print(warn)
      cutoff_frac = 0.5
    endif
    notch_fraclist = "0," //What does this do?
  endif
  return do_lowpass
end


function fdRV_process_set_notch(notch, notch_fracList, measureFreq)
  string notch &notch_fracList
  variable measureFreq

  variable doNotch=0,numNotch=0
	if(cmpstr(notch, "")!=0)
		// add notch filter(s)
		doNotch = 1
		numNotch = itemsinlist(notch,",")
		for(i=0;i<numNotch;i+=1)
			notch_fracList = addlistitem(num2str(str2num(stringfromlist(i,notch,","))/measureFreq),notch_fracList,",",itemsinlist(notch_fracList))
		endfor
	endif
  return do_notch
end


function fdRV_process_setup_filters(FIRcoefs, coefList, cutoff_frac, notch_fracList, numpts, do_lowpass, do_notch)
  variable &FIRcoefs, cutoff_frac, numpts, do_lowpass, do_notch
  string &coefList, notch_fracList

  if(numpts < 101)
    FIRcoefs = numpts
  else
    FIRcoefs = 101
  endif

  string coef = ""
  variable j=0,numfilter=0
  // add RC filter
  if(doLowpass == 1)
    coef = "coefs"+num2istr(numfilter)
    make/o/d/n=0 $coef
    filterfir/lo={cutoff_frac,cutoff_frac,FIRcoefs}/coef $coef
    coefList = addlistitem(coef,coefList,",",itemsinlist(coefList))
    numfilter += 1
  endif
  // add notch filter(s)
  if(doNotch == 1)
    for(j=0;j<numNotch;j+=1)
      coef = "coefs"+num2istr(numfilter)
      make/o/d/n=0 $coef
      filterfir/nmf={str2num(stringfromlist(j,notch_fraclist,",")),15.0/measureFreq,1.0e-8,1}/coef $coef
      coefList = addlistitem(coef,coefList,",",itemsinlist(coefList))
      numfilter += 1
    endfor
  endif
  return FIRcoefs
end







function fdacRecordValues(instrID,rowNum,rampCh,start,fin,numpts,[delay,ramprate,RCcutoff,numAverage,notch,direction])
	// RecordValues for FastDAC's. This function should replace RecordValues in scan functions.
	// j is outer scan index, if it's a 1D scan just set j=0.
	// rampCh is a comma seperated string containing the channels that should be ramped.
	// Data processing:
	// 		- RCcutoff set the lowpass cutoff frequency
	//		- average set the number of points to average
	//		- nocth sets the notch frequency, as a comma seperated list (width is fixed at 5Hz)
	// direction - used to reverse direction of scan (e.g. in alternating repeat scan) - leave start/fin unchanged
	// 	   It is not sufficient to reverse start/fin because sc_distribute_data also needs to know
	variable instrID, rowNum
	string rampCh, start, fin
	variable numpts, delay, ramprate, RCcutoff, numAverage, direction
	string notch
	nvar sc_is2d, sc_startx, sc_starty, sc_finx, sc_starty, sc_finy, sc_numptsx, sc_numptsy
	nvar sc_abortsweep, sc_pause, sc_scanstarttime
	wave/t fadcvalstr, fdacvalstr
	wave fadcattr

	// Check inputs and set defaults
	ramprate = paramisdefault(ramprate) ? 1000 : ramprate
	delay = paramisdefault(delay) ? 0 : delay
	direction = paramisdefault(direction) ? 1 : direction
	if (!(direction == 1 || direction == -1))  // Abort if direction is not 1 or -1
		abort "ERROR[fdacRecordValues]: Direction must be 1 or -1"
	endif
	if (direction == -1)  // Switch start and end values to scan in reverse direction
		string temp = start
		start = fin
		fin = temp
	endif

	// compare to earlier call of InitializeWaves
	fdRV_check_init()

	// Everything below has to be changed if we get hardware triggers!
	// Check that dac and adc channels are all on the same device and sort lists
	// of DAC and ADC channels for scan.
	// When (if) we get hardware triggers on the fastdacs, this function call should
	// be replaced by a function that sorts DAC and ADC channels based on which device
	// they belong to.

	struct fdacChLists scanList
	fdRV_set_scanList(scanList, rampCh, start, fin)

	// get ADC sampling speed
	variable samplingFreq = getfadcSpeed(instrID)
	variable measureFreq = samplingFreq/getNumFADC()  //Because sampling is split between number of ADCs being read //TODO: This needs to be adapted for multiple FastDacs

	variable eff_ramprate = 0, answer = 0, i=0
	string question = ""

	if(rowNum == 0)
		fdRV_check_ramprates(measureFreq, numpts, rampCh, scanList)
		fdRV_check_lims(scanList)
	endif

	fdRV_ramp_start(instrID, scanList, ramprate)
	sc_sleep(delay)  // Settle time for 2D sweeps

	fdRV_start_INT_RAMP(scanList)

	// hold incoming data chunks in string and distribute to data waves
	variable numADCs = itemsinlist(scanList.adclist,",")
	string buffer = ""
	variable bytes_read = 0, plotUpdateTime = 15e-3, totaldump = 0,  saveBuffer = 1000
	variable bufferDumpStart = stopMSTimer(-2)
	variable totalByteReturn = numADCs*2*numpts

	variable read_chunk = fdRV_get_read_chunk_size(numADCs, numpts, measFreq, totalByteReturn)
	do
		fdRV_read_chunk(instrID, read_chunk, buffer)  // puts data into buffer
		fdRV_distribute_data(buffer, scanList, bytes_read, totalByteReturn, numADCs, read_chunk, rowNum, direction)
		bytes_read += read_chunk
		totaldump = bytesSec*(stopmstimer(-2)-bufferDumpStart)*1e-6  // Expected amount of bytes in buffer
		if(totaldump-bytes_read < saveBuffer)  // if we aren't too far behind
			// we can update all plots
			// should take ~15ms extra
			fdRV_update_graphs()
		endif
		fdRV_check_sweepstate()
	while(totalByteReturn-bytes_read > read_chunk)

	// do one last read if any data left to read
	variable bytes_left = totalByteReturn-bytes_read
	if(bytes_left > 0)
		fdRV_read_chunk(instrID, bytes_left, buffer)  // puts data into buffer
		fdRV_distribute_data(buffer, scanList, bytes_read, totalByteReturn, numADCs, bytes_left, rowNum, direction)
		fdRV_check_sweepstate()
		doupdate
	endif
	variable looptime = (stopmstimer(-2)-bufferDumpStart)*1e-6

	// update window
	buffer = readInstr(instrID)
	buffer = sc_stripTermination(buffer,"\r\n")
	if(fdacCheckResponse(buffer,cmd,isString=1,expectedResponse="RAMP_FINISHED"))
		fdRV_update_window(instrID, scanList)
	endif

	/////////////////////////
	//// Post processing ////
	/////////////////////////

	variable cutoff_frac
	string notch_fracList

	variable do_lowpass = fdRV_process_set_cutoff(RCCutoff, cutoff_frac, notch_fracList)
	variable do_notch = fdRV_process_set_notch(notch, notch_fracList, measureFreq)

	variable doAverage=0
	doaverage = (numAverage != 0) ? 1 : 0 // If numaverage isn't zero then do average

	// setup FIR (Finite Impluse Response) filter(s)
	variable FIRcoefs
	string coefList
	fdRV_process_setup_filters(FIRcoefs, coefList, cutoff_frac, notch_fracList, numpts, do_lowpass, do_notch)

	// apply filters
	if(doLowpass == 1 || doNotch == 1)
		sc_applyfilters(coefList,scanList.adclist,doLowpass,doNotch,cutoff_frac,measureFreq,FIRcoefs,notch_fraclist,rowNum)
	endif

	// average datawaves
	variable lastRow = sc_lastrow(rowNum)
	if(doAverage == 1)
		sc_averageDataWaves(numAverage,scanList.adcList,lastRow,rowNum)
	endif

		// check abort/pause status
	fdRV_check_sweepstate()
	return looptime
end
