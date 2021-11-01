/////////////// Dot Tuning Stuff ///////////////

function DotTuneAround(x, y, width_x, width_y, channelx, channely, [sweeprate, ramprate_x, numptsy, csname])
// Goes to x, y. Sets charge sensor to target_current. Scans2D around x, y +- width.
	variable x, y, width_x, width_y, ramprate_x
	variable sweeprate, numptsy
	string channelx, channely, csname
	
	variable natarget = 725//595//750//287 //1335   // ADC reading in mV to get most sensitive part of CS
	variable rccutoff = 1000
	sweeprate = paramisdefault(sweeprate) ? 300 : sweeprate
	numptsy = paramisdefault(numptsy) ? 21 : numptsy
	csname = selectstring(paramisdefault(csname), csname, "CSQ")
	ramprate_x = paramisdefault(ramprate_x) ? 1000 : ramprate_x
	
	
	nvar fd
	rampmultiplefdac(fd, channelx, x, ramprate=ramprate_x)
	rampmultiplefdac(fd, channely, y)
	
	CorrectChargeSensor(fd=fd, fdchannelstr=csname, fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1)
	ScanFastDAC2D(fd, x-width_x, x+width_x, channelx, y-width_y, y+width_y, channely, numptsy, sweeprate=sweeprate, rampratex=ramprate_x, nosave=0, comments="Dot Tuning")
	wave tempwave = $"cscurrent_2d"
	nvar filenum
	displaydiff(tempwave, filenum=filenum-1)
end


function steptempscanSomething()
	nvar fd
	svar xld

//	make/o targettemps =  {300, 275, 250, 225, 200, 175, 150, 125, 100, 75, 50, 40, 30, 20}
//	make/o targettemps =  {200, 175, 150, 125, 100, 75, 50, 40, 30, 20}
//	make/o targettemps =  {300, 250, 200, 150, 100, 75, 50, 35}
	make/o targettemps =  {50}

//	make/o targettemps =  {30, 20}
//	make/o targettemps =  {40, 30, 20}
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

		i+=1
	while ( i<numpnts(targettemps) )

	// kill temperature control
	setLS370heaterOff(xld)
	resetLS370exclusivereader(xld)
	asleep(60.0*60)

//	ScanTransitionMany()
//	EntropyVsHeaterBias()

end




function ScanEntropyRepeat([num, center_first, balance_multiplier, width, hqpc_bias, additional_comments, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center])
	variable num, center_first, balance_multiplier, width, hqpc_bias, repeat_multiplier, freq, sweeprate, two_part, repeats, cs_target, center
	string additional_comments
	nvar fd
	
	num = paramisdefault(num) ? 										INF : num
	center_first = paramisdefault(center_first) ? 				0 : center_first
	balance_multiplier = paramisdefault(balance_multiplier) ? 	1 : balance_multiplier
	hqpc_bias = paramisdefault(hqpc_bias) ? 						50 : hqpc_bias
	repeat_multiplier = paramisDefault(repeat_multiplier) ? 	1 : repeat_multiplier
	sweeprate = paramisdefault(sweeprate) ? 						10 : sweeprate
	freq = paramisdefault(freq) ? 									12.5 : freq
	two_part = paramisdefault(two_part) ? 							0 : two_part
	center = paramisdefault(center) ? 								0 : center

	if (two_part == 1 && !paramisdefault(repeats))
		abort "repeats is only meant to be set for a one part scan, not two part"
	endif
	
	variable nosave = 0
	
	variable width1 = paramisdefault(width) ? 1000 : width
	variable width2 = width1/3
	variable repeats1 = 2*repeat_multiplier
	variable repeats2 = 30*repeat_multiplier
	string comments = "transition, square entropy, repeat, "
	if (!paramisdefault(additional_comments))
		sprintf comments, "%s%s, ", comments, additional_comments
	endif
	
	variable splus = hqpc_bias, sminus=-hqpc_bias	
	SetupEntropySquareWaves(freq=freq, cycles=1, hqpc_plus=splus, hqpc_minus=sminus, balance_multiplier=balance_multiplier)

//	variable cplus=-splus*0.031 * balance_multiplier, cminus=-sminus*0.031 * balance_multiplier
//	SetupEntropySquareWaves_unequal(freq=freq, hqpc_plus=splus, hqpc_minus=sminus, balance_multiplier=balance_multiplier)

	variable mid, r
	if (center_first)
		rampmultiplefdac(fd, "ACC/100", center)
		centerontransition(gate="ESP", width=30)
		rampmultiplefdac(fd, "ACC/100", center-200)
		if (!paramisdefault(cs_target))
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1, natarget=cs_target)		
		else
			CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)		
		endif
		rampmultiplefdac(fd, "ACC/100", center)
		mid = centerontransition(gate="ACC/100", width=200, single_only=1)
		if (numtype(mid) == 2)
			mid = center
		endif
	else
		mid = center
	endif
	
	variable i=0
	do
		if(paramisdefault(num))
			printf "Starting scan %d of \u221E\r", i
		else
			printf "Starting scan %d of %d\r", i, num
		endif 	
		if (two_part == 1)
			ScanFastDACrepeat(fd, mid-width1, mid+width1, "ACC/100", repeats1, sweeprate=sweeprate, delay=0.2, comments=comments+", part1of2", use_awg=1, nosave=nosave)							
			ScanFastDACrepeat(fd, mid-width2, mid+width2, "ACC/100", repeats2, sweeprate=sweeprate, delay=0.2, comments=comments+", part2of2", use_awg=1, nosave=nosave)			
		else
			if (!paramisDefault(repeats) && repeats > 0)
				r = repeats
			else
				r = repeats2
			endif
			ScanFastDACrepeat(fd, mid-width1, mid+width1, "ACC/100", r, sweeprate=sweeprate, delay=0.2, comments=comments, use_awg=1, nosave=nosave)						
		endif
		rampmultiplefdac(fd, "ACC/100", mid)	
		i++
	while (i<num)
end



function ScanTransition([sweeprate, width, ramprate, repeats, center_first, center_gate, center_width, sweep_gate, additional_comments, mid])
	variable sweeprate, width, ramprate, repeats, center_first, center_width, mid
	string center_gate, sweep_gate, additional_comments
	nvar fd
	
	sweeprate = paramisdefault(sweeprate) ? 100 : sweeprate
	width = paramisdefault(width) ? 200 : width
	ramprate = paramisDefault(ramprate) ? 1000 : ramprate
	repeats = paramIsDefault(repeats) ? 10 : repeats
	mid = paramIsDefault(mid) ? 0 : mid
	// let center_first default to 0
	sweep_gate = selectstring(paramisdefault(sweep_gate), sweep_gate, "ACC/100")
	center_gate = selectstring(paramisdefault(center_gate), center_gate, "ESP")
	center_width = paramisDefault(center_width) ? 50 : center_width
	additional_comments = selectstring(paramisdefault(additional_comments), additional_comments, "")
	
	if (center_first)
		rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
		mid = centerontransition(gate=center_gate, width=center_width, single_only=1)
		print "Centered at ESP="+num2str(mid)+"mV"
		rampmultiplefdac(fd, sweep_gate, -width*0.5, ramprate=ramprate)	
		CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, direction=1)  
	endif
	
	ScanFastDACrepeat(fd, mid-width, mid+width, sweep_gate, repeats, sweeprate=sweeprate, ramprate=ramprate, nosave=0, delay=0.01, comments="transition, repeat" + additional_comments)
	rampmultiplefdac(fd, sweep_gate, mid, ramprate=ramprate)
end

function ScanTransitionNoise()
	nvar fd
	
	variable mid
	variable natarget = 738*5/3
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1)  
	rampmultiplefdac(fd, "ACC/100", 0, ramprate=10000)
	mid = centerontransition(gate="ESP", width=50, single_only=0)
	print "Centered at ESP="+num2str(mid)+"mV"
	rampmultiplefdac(fd, "ACC/100", -200, ramprate=10000)	
	CorrectChargeSensor(fd=fd, fdchannelstr="CSQ", fadcID=fd, fadcchannel=0, check=0, natarget=natarget, direction=1) 
	
	mid = centerontransition(gate="ACC/100", width=1000, single_only=0)
	print "Centered BEFORE at ACC/100="+num2str(mid)+"mV"
	ScanFastDAC(fd, -1199, -1201, "BDL_BD2S", numpts=761400, nosave=0, comments="readvstime, ON transition")
	mid = centerontransition(gate="ACC/100", width=1000, single_only=0)
	print "Centered AFTER at ACC/100="+num2str(mid)+"mV"
	
	rampmultiplefdac(fd, "ACC/100", -350, ramprate=10000)
	ScanFastDAC(fd, -1199, -1201, "BDL_BD2S", numpts=761400, nosave=0, comments="readvstime, OFF transition")
	
	rampmultiplefdac(fd, "ACC/100", 0, ramprate=10000)
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
					// Do Scan here
				endfor
			endfor
		endfor
	endfor
	
	print "Finished all scans"
end

