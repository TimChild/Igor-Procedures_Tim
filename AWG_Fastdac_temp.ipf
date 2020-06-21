function ScanFastDAC(instrID, start, fin, channels, [numpts, sweeprate, ramprate, delay, y_label, comments, RCcutoff, numAverage, notch, nosave]) //Units: mV
	// sweep one or more FastDac channels from start to fin using either numpnts or sweeprate /mV/s
	// Note: ramprate is for ramping to beginning of scan ONLY
	// Note: Delay is the wait after rampoint to start position ONLY
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
	// TODO: Should put checks here on x, y lims?
	//RampMultipleFDac(instrID, channels, start)
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
















function fdAWG_add_wave(instrID, wave_num, add_wave)
	// Very basic command which adds to the AWGs stored in the fastdac
	variable instrID
	variable wave_num  	// Which AWG to add to (currently allowed 0 or 1)
	wave add_wave		// add_wave should be 2D with add_wave[0] = mV setpoint for each step in wave
					   		// 									 add_wave[1] = how many samples to stay at each setpoint



                        // ADD_WAVE,<wave number (for now just 0 or 1)>,<Setpoint 0 in mV>,<Number of samples at setpoint 0>,….<Setpoint n in mV>,<Number of samples at Setpoint n>
                        //
                        // Response:
                        //
                        // WAVE,<wavenumber>,<total number of setpoints accumulated in waveform>
                        //
                        // Example:
                        //
                        // ADD_WAVE,0,300.1,50,-300.1,200
                        //
                        // Response:
                        //
                        // WAVE,0,2

   waveStats add_wave
   if (dimsize(add_wave, 0) != 2 || V_numNans !=0) // Check 2D(TODO: Check 0/1) and no NaNs
      abort "ERROR[fdAWG_add_wave]: must be 2D (setpoints, samples) and contain no NaNs"
   endif
   if (wave_num != 0 || wave_num != 1)  // Check adding to AWG 0 or 1
      abort "ERROR[fdAWG_add_wave]: Only supports AWG wave 0 or 1"
   endif

   // TODO: Any other checks on add_wave? i.e. setpoints within hardware/software lims, sample lengths within reasonable lims
   // TODO: Will have to check against lims when setting ramp as thats when DACs are chosen to output.
   // TODO: Should check that all sample_lengths are integers (i.e. not getting sent times in seconds)

   variable i=0
   string buffer = ""
   for(i=0;i<numpnts(add_wave);i++)
      sprintf buffer "%s,%d,%d,", buffer, add_wave[0][i], add_wave[1][i] // TODO: Check got correct wave dim here
   endfor

   buffer = buffer[0,strlen(buffer)-2]  // chop off last ","

   string cmd = ""
	// convert to string in form "ADD_WAVE,<wave_num>,<sp0>,<#sp0>,...,<spn>,<#spn>"
   sprintf cmd "ADD_WAVE,%d,%s", wave_num, buffer

   if (strlen(cmd) > 256)
      sprintf buffer "ERROR[fdAWG_add_wave]: command length is %d, which exceeds fDAC buffer size of 256. Add to AWG in smaller chunks", strlen(cmd)
      abort buffer
   endif

	 string response
    response = queryInstr(instrID, cmd+"\r", read_term="\n")
    response = sc_stripTermination(response, "\r\n")

    string expected_response
    sprintf expected_response "WAVE,%d,%d", wave_num, numpnts(add_wave)
    if(fdacCheckResponse(response, cmd, isString=1, expectedResponse=expected_response))
       wave AWG_wave = fdAWG_get_AWG_wave(wave_num)
       AWG_wave = AWG_wave+add_wave  // TODO: check this concatenates properly
    else
       abort "ERROR[fdAWG_add_wave]: Failed to add add_wave to AWG_wave"+ num2str(wave_num)
    endif
end


function/wave fdAWG_get_AWG_wave(wave_num)
   // Either returns existing AWG_wave<wave_num> or creates and returns
   variable wave_num
   if (wave_num != 0 || wave_num != 1)  // Check adding to AWG 0 or 1
      abort "ERROR[fdAWG_get_AWG_wave]: Only supports AWG wave 0 or 1"
   endif

   string wn = ""
   sprintf wn, "AWG_wave%d", wave_num
   wave AWG_wave = $wn
   if(!waveExists(AWG_wave))
      make/o/n=(-1,2) AWG_wave // TODO: check how dimensions of this look
   endif
   return AWG_wave
end

function fdAWG_clear_wave(instrID, wave_num)
	// Clears AWG# from the fastdac and the corresponding global wave in IGOR
	variable instrID
	variable wave_num // Which AWG to clear (currently allowed 0 or 1)

   // CLR_WAVE,<wave number>
   //
   // Response:
   //
   // WAVE,<wave number>,0
   //
   // Example:
   //
   // CLR_WAVE,1
   //
   // Response:
   //
   // WAVE,1,0

	string cmd
	sprintf cmd, "CLR_WAVE,%d", wave_num
	//send command
	string response
   response = queryInstr(instrID, cmd+"\r", read_term="\n")
   response = sc_stripTermination(response, "\r\n")

   string expected_response
   sprintf expected_response "WAVE,%d,0", wave_num
   if(fdacCheckResponse(response, cmd, isstring=1,expectedResponse=expected_response))
		wave AWG_wave = fdAWG_get_AWG_wave(wave_num)
		killwaves AWG_wave
   else
      abort "ERROR[fdAWG_clear_wave]: Error while clearing AWG_wave"+num2str(wave_num)
   endif
end


function fdAWG_start_AWG_RAMP(S, AWG_list)
   struct fdRV_Struct &S
   struct fdAWG_list &AWG_list

   // AWG_RAMP,<number of waveforms>,<dac channel(s) to output waveform 0>,<dac channel(s) to output waveform n>,<dac channel(s) to ramp>,<adc channel(s)>,<initial dac voltage 1>,<…>,<initial dac voltage n>,<final dac voltage 1>,<…>,<final dac voltage n>,<# of waveform repetitions at each ramp step>,<# of ramp steps>
   //
   // Example:
   //
   // AWG_RAMP,2,012,345,67,0,-1000,1000,-2000,2000,50,50
   //
   // Response:
   //
   // <(2500 * waveform length) samples from ADC0>RAMP_FINISHED

   string cmd = "", dacs="", adcs=""
   dacs = replacestring(",",S.fdList.daclist,"")
	adcs = replacestring(",",S.fdList.adclist,"")
   // OPERATION, #N AWs, AW_dacs, DAC CHANNELS, ADC CHANNELS, INITIAL VOLTAGES, FINAL VOLTAGES, # OF Wave cycles per step, # ramp steps
   // Note: AW_dacs is formatted (dacs_for_wave0, dacs_for_wave1, .... e.g. '01,23' for Dacs 0,1 to output wave0, Dacs 2,3 to output wave1)
	sprintf cmd, "AWG_RAMP,%d, %s, %s,%s,%s,%s, %d, %d\r", AWG_list.numWaves, AWG_list.dacs, dacs, adcs, S.fdList.startVal, S.fdList.finVal, AWG_list.numCycles, AWG_list.numSteps
	writeInstr(S.sv.instrID,cmd)

end





//////////////////////////////////////
///////////// Structs ////////////////
//////////////////////////////////////



structure fdAWG_list
   // Note: AW_dacs is formatted (dacs_for_wave0, dacs_for_wave1, .... e.g. '01,23' for Dacs 0,1 to output wave0, Dacs 2,3 to output wave1)
   string dacs
   variable numWaves   // # different AWGs (currently 1 or 2 only)
   variable waveLen    // in samples (i.e. sum of samples at each setpoint for a single wave cycle)
   variable numCycles  // # wave cycles per DAC step for a full 1D scan
   variable numSteps   // # DAC steps for a full 1D scan
endstructure

structure fdRV_Filter_options
	// For use in Scan functions to pass in filter options in a neater way
   variable RCCutoff
   variable numAverage
   string notch_list
endstructure


















function fdAWG_record_values(ScanVars, AWG_list, FilterOpts, rowNum)
   struct sc_scanVars &scanVars
   struct fdAWG_list &AWG_list
   struct fdRV_Filter_options &FilterOpts
   variable rowNum
   // Almost exactly the same as fdacRecordValues with:
   //    Improved usage of structures
   //    Ability to use FDAC Arbitrary Wave Generator
   // Note: May be worth using this function to replace fdacRecordValues at somepoint
   // Note: Only works for 1 FastDAC! Not sure what implementation will look like for multiple yet


   struct fdRV_Struct S
   // Set up FastDac Record Values Struct.
   // Note: FilterOpts get stored in S.pl (pl= ProcessList)
   // Note: samplingFreq, measureFreq, numADCs also setup here.
   // Note: This is also where start, fin variables in ScanVars are converted to strings for FastDAC
   fdAWG_set_struct_base_vars(S, ScanVars, FilterOpts, rowNum)

   // Check InitWaves was run with fastdac=1
   fdRV_check_init()

   // Check within limits and ramprates
   fdRV_check_rr_lims(S)

   // Ramp to start of scan ignoring lims because already checked
   fdRV_ramp_start(S.sv, S.fdList, ignore_lims = 1)
   sc_sleep(S.sv.delayx) // Settle time for 2D sweeps

   // Start the AWG_RAMP
   fdAWG_start_AWG_RAMP(S, AWG_list)

   variable totalByteReturn = AWG_list.numCycles*AWG_list.numSteps*AWG_list.waveLen
   // TODO: Either check that totalByteReturn is a multiple of numADCs, or that waveLen is a multiple of ADCs to reduce aliasing
   variable looptime = 0
   // TODO: Is is OK to be storing datapoints with increasing x even though steps will be only every AWG.waveLen/numADCs
   looptime = fdRV_record_buffer(S, totalByteReturn)

   // update window
	string endstr
	endstr = readInstr(S.sv.instrID)
	endstr = sc_stripTermination(endstr,"\r\n")
	if(fdacCheckResponse(endstr,"AWG_RAMP...",isString=1,expectedResponse="RAMP_FINISHED"))
		fdRV_update_window(S.sv.instrID, S.fdList, S.numADCs)
	endif

   /////////////////////////
	//// Post processing ////
	/////////////////////////

	fdRV_Process_data(S)

		// check abort/pause status
	fdRV_check_sweepstate(S.sv.instrID)
	return looptime

end

function fdAWG_set_struct_base_vars(S, ScanVals, FilterOpts, rowNum)
   struct fdRV_Struct &S
   struct sc_ScanVars &scanVals
   struct fdRV_Filter_options &FilterOpts
   variable rowNum
   S.sv = ScanVals
   S.rowNum = rowNum

   string starts = "", fins = ""
   fd_format_setpoints(S.sv.startx, S.sv.finx, S.sv.channelsx, starts, fins)  // Gets starts/fins in FD string format
   fdRV_set_scanList(s.fdList, S.sv.channelsx, starts, fins)  // Sets fdList with CHs, starts, fins

   S.pl.RCCutoff = FilterOpts.RCcutoff
   S.pl.numAverage = FilterOpts.numAverage
   S.pl.notch_list = FilterOpts.notch_list

   S.pl.coefList = ""

   fdRV_set_measureFreq(S) // Sets S.samplingFreq/measureFreq/numADCs
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

	// nvar sc_is2d, sc_startx, sc_starty, sc_finx, sc_starty, sc_finy, sc_numptsx, sc_numptsy
	// nvar sc_abortsweep, sc_pause, sc_scanstarttime
	// wave/t fadcvalstr, fdacvalstr
	// wave fadcattr

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

	struct fdRV_Struct S // Contains structs and variables to be used in scan
	fdRV_set_struct_base_vars(S,instrID,rowNum,rampCh,start,fin,numpts,delay,ramprate,RCcutoff,numAverage,notch,direction)

	// compare to earlier call of InitializeWaves
	fdRV_check_init()

	// Everything below has to be changed if we get hardware triggers!
	// Check that dac and adc channels are all on the same device and sort lists
	// of DAC and ADC channels for scan.
	// When (if) we get hardware triggers on the fastdacs, this function call should
	// be replaced by a function that sorts DAC and ADC channels based on which device
	// they belong to.


	// Set samplingFreq, numADCs, measureFreq
	fdRV_set_measureFreq(S)

	// Check within limits and ramprates
	fdRV_check_rr_lims(S)

	fdRV_ramp_start(S.sv, S.fdList, ignore_lims = 1)
	sc_sleep(delay)  // Settle time for 2D sweeps

	// Start the fastdac INT_RAMP
	fdRV_start_INT_RAMP(S.sv, S.fdList)

	// Record all the values sent back from the FastDAC to respective waves
	variable totalByteReturn = S.numADCs*2*S.sv.numptsx
	variable looptime = 0
	looptime = fdRV_record_buffer(S, totalByteReturn) // And get the total time

	// update window
	string endstr
	endstr = readInstr(S.sv.instrID)
	endstr = sc_stripTermination(endstr,"\r\n")
	if(fdacCheckResponse(endstr,"INT_RAMP...",isString=1,expectedResponse="RAMP_FINISHED"))
		fdRV_update_window(S.sv.instrID, S.fdList, S.numADCs)
	endif


	/////////////////////////
	//// Post processing ////
	/////////////////////////

	fdRV_Process_data(S)

		// check abort/pause status
	fdRV_check_sweepstate(S.sv.instrID)
	return looptime
end


function fdRV_check_init()
  nvar fastdac_init
  if(fastdac_init != 1)
    print("[ERROR] \"RecordValues\": Trying to record fastDACs, but they weren't initialized by \"InitializeWaves\"")
    abort
  endif
end

function fdRV_set_scanList(scanList, rampCh, start, fin)
  struct fdRV_ChLists &scanList  // alters passed struct
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


function fdRV_check_rr_lims(S)
   struct fdRV_Struct &S

   variable eff_ramprate = 0, answer = 0, i=0
   string question = ""
   if(S.rowNum == 0)
      fdRV_check_ramprates(S.measureFreq, S.sv.numptsx, S.fdList)
      fdRV_check_lims(S.fdList)
   endif
end


function fdRV_check_ramprates(measFreq, numpts, scanList)
  // check if effective ramprate is higher than software limits
  variable measFreq, numpts
  struct fdRV_ChLists &scanList

  wave/T fdacvalstr
  svar activegraphs

  variable eff_ramprate, answer, i, k, channel
  string question
  for(i=0;i<itemsinlist(ScanList.dacList,",");i+=1)
    eff_ramprate = abs(str2num(stringfromlist(i,scanlist.startval,","))-str2num(stringfromlist(i,scanlist.finval,",")))*(measFreq/numpts)
    channel = str2num(stringfromlist(i, scanList.dacList, ","))
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
	struct fdRV_ChLists &scanList

	wave/T fdacvalstr
	svar activegraphs
	variable answer, i, k
	string softLimitPositive = "", softLimitNegative = "", expr = "(-?[[:digit:]]+),([[:digit:]]+)", question
	variable startval = 0, finval = 0
	for(i=0;i<itemsinlist(scanlist.daclist,",");i+=1)
		splitstring/e=(expr) fdacvalstr[str2num(stringfromlist(i,scanList.daclist,","))][2], softLimitNegative, softLimitPositive
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


function fdRV_ramp_start(scanVars, scanList, [ignore_lims])
  // move DAC channels to starting point
  struct sc_scanVars &scanVars
  struct fdRV_ChLists &scanList
  variable ignore_lims

  variable i
  for(i=0;i<itemsinlist(scanList.daclist,",");i+=1)
    rampOutputfdac(scanVars.instrID,str2num(stringfromlist(i,scanList.daclist,",")),str2num(stringfromlist(i,scanList.startVal,",")),ramprate=scanVars.rampratex, ignore_lims=ignore_lims)
  endfor
end


function fdRV_start_INT_RAMP(scanVars, scanList)
	// build command and start ramp
	// for now we only have to send one command to one device.
	struct sc_scanVars &scanVars
	struct fdRV_ChLists &scanList


	string cmd = "", dacs="", adcs=""
	dacs = replacestring(",",scanlist.daclist,"")
	adcs = replacestring(",",scanlist.adclist,"")
	// OPERATION, DAC CHANNELS, ADC CHANNELS, INITIAL VOLTAGES, FINAL VOLTAGES, # OF STEPS
	sprintf cmd, "INT_RAMP,%s,%s,%s,%s,%d\r", dacs, adcs, scanList.startVal, scanList.finVal, scanVars.numptsx
	writeInstr(scanVars.instrID,cmd)
end



function fdRV_record_buffer(S, totalByteReturn)
   struct fdRV_Struct &S
   variable totalByteReturn

   // hold incoming data chunks in string and distribute to data waves
   string buffer = ""
   variable bytes_read = 0, plotUpdateTime = 15e-3, totaldump = 0,  saveBuffer = 1000
   variable bufferDumpStart = stopMSTimer(-2)

   variable bytesSec = roundNum(2*S.measureFreq*S.numADCs,0)
   variable read_chunk = fdRV_get_read_chunk_size(S.numADCs, S.sv.numptsx, bytesSec, totalByteReturn)
   do
      fdRV_read_chunk(S.sv.instrID, read_chunk, buffer)  // puts data into buffer
      fdRV_distribute_data(buffer, S.fdList, bytes_read, totalByteReturn, S.numADCs, read_chunk, S.rowNum, S.sv.direction)
      bytes_read += read_chunk
      totaldump = bytesSec*(stopmstimer(-2)-bufferDumpStart)*1e-6  // Expected amount of bytes in buffer
      if(totaldump-bytes_read < saveBuffer)  // if we aren't too far behind
         // we can update all plots
         // should take ~15ms extra
         fdRV_update_graphs()
      endif
      fdRV_check_sweepstate(S.sv.instrID)
   while(totalByteReturn-bytes_read > read_chunk)

   // do one last read if any data left to read
   variable bytes_left = totalByteReturn-bytes_read
   if(bytes_left > 0)
      fdRV_read_chunk(S.sv.instrID, bytes_left, buffer)  // puts data into buffer
      fdRV_distribute_data(buffer, S.fdList, bytes_read, totalByteReturn, S.numADCs, bytes_left, S.rowNum, S.sv.direction)
      fdRV_check_sweepstate(S.sv.instrID)
      doupdate
   endif
   variable looptime = (stopmstimer(-2)-bufferDumpStart)*1e-6
   return looptime
end


function fdRV_get_read_chunk_size(numADCs, numpts, bytesSec, totalByteReturn)
  // Returns the size of chunks that should be read at a time
  variable numADCs, numpts, bytesSec, totalByteReturn

  variable read_chunk=0
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

function fdRV_check_sweepstate(instrID)
  	// if abort button pressed then stops FDAC sweep then aborts
  	variable instrID
	variable errCode
	nvar sc_abortsweep
	nvar sc_pause
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
  struct fdRV_ChLists &scanList
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


function fdRV_update_window(instrID, scanList, numAdcs)
  struct fdRV_ChLists &scanList
  variable instrID, numADCs

  wave/T fdacvalstr

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


function fdRV_Process_data(S)
   struct fdRV_Struct &S

   fdRV_process_set_cutoff(S.pl) // sets pl.do_notch accordingly

   fdRV_process_set_notch(S.pl)

   S.pl.do_average = (S.pl.numAverage != 0) ? 1 : 0 // If numaverage isn't zero then do average

   // setup FIR (Finite Impluse Response) filter(s)

   fdRV_process_setup_filters(S.pl, S.sv.numptsx)

   fdRV_do_filters_average(S.PL, S.fdList, S.rowNum)
end


function fdRV_process_set_cutoff(PL)
   struct fdRV_processList &PL

   string warn = ""
   if(PL.RCCutoff != 0)
      // add lowpass filter
      PL.do_Lowpass = 1
      PL.cutoff_frac = PL.RCcutoff/PL.measureFreq
      if(PL.cutoff_frac > 0.5)
         print("[WARNING] \"fdacRecordValues\": RC cutoff frequency must be lower than half the measuring frequency!")
         sprintf warn, "Setting it to %.2f", 0.5*PL.measureFreq
         print(warn)
         PL.cutoff_frac = 0.5
      endif
      PL.notch_fraclist = "0," //What does this do?
  endif
end


function fdRV_process_set_notch(PL)
   struct fdRV_processList &PL

   variable i=0
   if(cmpstr(PL.notch_list, "")!=0)
		// add notch filter(s)
		PL.do_Notch = 1
		PL.numNotch = itemsinlist(PL.notch_list,",")
		for(i=0;i<PL.numNotch;i+=1)
			PL.notch_fracList = addlistitem(num2str(str2num(stringfromlist(i,PL.notch_list,","))/PL.measureFreq),PL.notch_fracList,",",itemsinlist(PL.notch_fracList))
		endfor
	endif
end


function fdRV_process_setup_filters(PL, numpts)
   struct fdRV_processList &PL
   variable numpts

   if(numpts < 101)
		PL.FIRcoefs = numpts
	else
		PL.FIRcoefs = 101
	endif

	string coef = ""
	variable j=0,numfilter=0
	// add RC filter
	if(PL.do_Lowpass == 1)
		coef = "coefs"+num2istr(numfilter)
		make/o/d/n=0 $coef
		filterfir/lo={PL.cutoff_frac,PL.cutoff_frac,PL.FIRcoefs}/coef $coef
		PL.coefList = addlistitem(coef,PL.coefList,",",itemsinlist(PL.coefList))
		numfilter += 1
	endif
	// add notch filter(s)
	if(PL.do_Notch == 1)
		for(j=0;j<PL.numNotch;j+=1)
			coef = "coefs"+num2istr(numfilter)
			make/o/d/n=0 $coef
			filterfir/nmf={str2num(stringfromlist(j,PL.notch_fraclist,",")),15.0/PL.measureFreq,1.0e-8,1}/coef $coef
			PL.coefList = addlistitem(coef,PL.coefList,",",itemsinlist(PL.coefList))
			numfilter += 1
		endfor
	endif
end


function fdRV_do_filters_average(PL, SL, rowNum)
   struct fdRV_processList &PL
   struct fdRV_ChLists &SL
   variable rowNum

   // apply filters
   if(PL.do_Lowpass == 1 || PL.do_Notch == 1)
      sc_applyfilters(PL.coefList,SL.adclist,PL.do_Lowpass,PL.do_Notch,PL.cutoff_frac,PL.measureFreq,PL.FIRcoefs,PL.notch_fraclist,rowNum)
   endif

   // average datawaves
   variable lastRow = sc_lastrow(rowNum)
   if(PL.do_Average == 1)
      sc_averageDataWaves(PL.numAverage,SL.adcList,lastRow,rowNum)
   endif
end


function fdRV_set_measureFreq(S)
   struct fdRV_Struct &S
   S.samplingFreq = getfadcSpeed(S.sv.instrID)
   S.numADCs = getNumFADC()
   S.measureFreq = S.samplingFreq/S.numADCs  //Because sampling is split between number of ADCs being read //TODO: This needs to be adapted for multiple FastDacs
	S.pl.measureFreq = S.measureFreq  // Also required for Processing
end

function fdRV_set_struct_base_vars(s, instrID,rowNum,rampCh,start,fin,numpts,delay,ramprate,RCcutoff,numAverage,notch,direction)
   struct fdRV_Struct &s
   variable instrID, rowNum
   string rampCh, start, fin
   variable numpts, delay, ramprate, RCcutoff, numAverage, direction
   string notch
   s.rowNum = rowNum
   sc_set_scanVars(s.sv, instrID, NaN, NaN, rampCh, numpts, ramprate, delay, direction=direction)
   fdRV_set_scanList(s.fdList, rampCh, start, fin)
   s.pl.RCcutoff = RCCutoff
   s.pl.numAverage = numAverage
   s.pl.notch_list = notch
   s.pl.coefList = ""
end


//Structure to hold all variables for fastdacRecordValues
structure fdRV_Struct
   struct fdRV_ChLists fdList   		// FD specific single sweep variables
   struct sc_scanVars sv         	// Common scan variables
   struct fdRV_processList pl   		// FD post processing variables
   struct sc_global_vars sc     	// SC global variables for scans
   // FD specific variables
   variable rowNum
   variable samplingFreq
   variable measureFreq
   variable numADCs
endstructure


// structure to hold DAC and ADC channels to be used in fdac scan.
structure fdRV_ChLists
		string dacList
		string adcList
		string startVal
		string finVal
endstructure


structure fdRV_processList
   variable RCCutoff
   string notch_list
   variable numAverage

   variable FIRcoefs
   string coefList
   variable cutoff_frac
   string notch_fracList
   variable numNotch

   variable measureFreq

   variable do_Lowpass
   variable do_notch
   variable do_average
endstructure




structure sc_scanVars
	// To make using and passing common scanVariables easier in scan routines
	// use sc_set_scanVars() as a nice way to initialize scanVars.
   variable instrID
   variable startx, finx, numptsx, delayx, rampratex
   variable starty, finy, numptsy, delayy, rampratey
   string channelsx
   string channelsy
   variable direction
endstructure


function sc_set_scanVars(s, instrID, startx, finx, channelsx, numptsx, rampratex, delayx, [starty, finy, channelsy, numptsy, rampratey, delayy, direction])
   // Function to make setting up scanVars struct easier.
   // Note: This is designed to store 2D variables, so if just using 1D you still have to specify x at the end of each variable
   struct sc_scanVars &s
   variable instrID
   variable startx, finx, numptsx, delayx, rampratex
   variable starty, finy, numptsy, delayy, rampratey
   string channelsx
   string channelsy
   variable direction

   s.instrID = instrID
   s.startx = startx
   s.finx = finx
   s.channelsx = channelsx
   s.numptsx = numptsx
   s.rampratex = rampratex
   s.delayx = delayx
   s.starty = paramisdefault(starty) ? NaN : starty
   s.finy = paramisdefault(finy) ? NaN : finy
   if (paramisdefault(channelsy))
		s.channelsy = ""
	endif
	s.numptsy = paramisdefault(numptsy) ? NaN : numptsy
   s.rampratey = paramisdefault(rampratey) ? NaN : rampratey
   s.delayy = paramisdefault(delayy) ? NaN : delayy
   s.direction = paramisdefault(direction) ? 1 : direction
end


structure sc_global_vars
	// Structure to make accessing common sc global variables easier and cleaner
   nvar sc_is2d, sc_startx, sc_starty, sc_finx, sc_finy, sc_numptsx, sc_numptsy
   nvar sc_abortsweep, sc_pause, sc_scanstarttime
   wave fadcattr
   wave/T fdacvalstr, facdvalstr
endstructure
