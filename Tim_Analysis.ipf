//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////// My Analysis ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////// Noise Spectrum ///////////////////////

function/wave IntegrateNoise(wv, dur)
	// Input 
	// wv: PSD or any wave that needs to be integrated and normalized
	// dur: time in seconds of sampling
	// Comments
	// Meant to be used with DSPPeriodogram set to normalize using PARS (Parseval's Thm)
	// dur would be duration of the time series passed into DSPPeriodogram 
	wave wv
	variable dur
	string wnname = nameofwave(wv) + "_int"
	duplicate/o wv $wnname
	wave intwv = $wnname
	integrate intwv
//	intwv = intwv*dur
	return intwv
end


function DisplayIntegratedNoise(sa_num, [text_label, show_smoothed])
	variable sa_num, show_smoothed
	string text_label
	
	if (sa_num < 0)
		nvar sanum
		sa_num = sanum-1
	endif
	
	string wn = "sasaved"+num2str(sa_num)
	string wn_lin = "sasavedlin"+num2str(sa_num)
	string wn_int = wn_lin + "_int"
	string wn_lin_smooth = wn_lin+"_smoothed"
//	display $wn
//	Label left "PSD dBnA/sqrt(Hz)"
//	Label bottom "Frequency /Hz"

	
	display $wn_lin
//	Label left "PSD dBnA/sqrt(Hz)"
	Label left "PSD nA^2/Hz"
	Label bottom "Frequency /Hz"
	ModifyGraph log(left)=1
	
	if (show_smoothed !=0)
		duplicate/o $wn_lin $wn_lin_smooth 
		appendToGraph $wn_lin_smooth
		wavestats/q $wn_lin_smooth
		resample/down=(round(v_npnts/1000)) $wn_lin_smooth 
		ModifyGraph rgb($wn_lin_smooth)=(4369,4369,4369)
	endif
	
	appendtograph/r $wn_int
	Label right "Int PSD nA^2"
	TextBox/C/N=SA_num/A=LT "SA"+num2str(sa_num)
	ModifyGraph rgb($wn_int)=(1,4,52428)
	
	if (!paramisdefault(text_label))
		textbox/C/N=text_label text_label
	endif

end


function PlotNoiseSpectrogram(numstart, numfinish, [measureFreq, stepSize])
// Make a 2D plot of single lines from a bunch of noise spectra
	variable numstart, numfinish
	variable measureFreq, stepSize
	nvar fd
	
	measureFreq = paramisdefault(measureFreq) ? getfadcspeed(fd) : measureFreq
	stepSize = paramisdefault(stepSize) ? 1 : stepSize
	
	string start = num2str(numstart)
	string finish = num2str(numfinish)
	variable numspectra = floor((numfinish+1-numstart)/stepsize)
	
	string tempspectra_wn = "SAsaved" + start
	wave tempspectra = $tempspectra_wn
	
	string wn = "spectrogram_" + start + "_" + finish +"_2D"
	Make/O/N=(numpnts(tempspectra), numspectra) $wn
	wave sgram = $wn
	
	variable i
	for(i = 0; i < numspectra; i++)
		tempspectra_wn = "SAsaved" + num2str(i*stepSize+numstart)
		wave tempspectra = $tempspectra_wn
		sgram[][i] = tempspectra[p]
	endfor
	
	// Plot result
	display; appendimage $wn
	ModifyImage $wn ctab= {*,*,RedWhiteBlue,0}
	TextBox/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 wn	
	ColorScale/C/N=text1/A=RC/E image=$wn
	setscale/i x, 0, measureFreq/(2.0), $wn
	Label left "Repeats"
	Label bottom "Frequency /Hz"

end



///////////////////////////////// Display/Analysis Functions ////////////////
function plot_waterfall(w, x_label, y_label, [y_spacing])
	wave w
	string x_label, y_label
	variable y_spacing
	
	display
	setWindow kwTopWin, graphicsTech=0		
	duplicate/o w tempwave
	variable i
	for (i=0; i<dimsize(w, 1); i++)
		tempwave[][i] = tempwave[p][i]+y_spacing*i
		AppendToGraph tempwave[][i]
	endfor
	scg_setupGraph1D(WinName(0,1), x_label, y_label=y_label)
end

function DisplayDiff(w, [x_label, y_label, filenum, numpts])
	wave w
	string x_label, y_label
	variable filenum, numpts
	
	x_label = selectstring(paramisdefault(x_label), x_label, "")
	y_label = selectstring(paramisdefault(y_label), y_label, "")
	numpts = paramisdefault(numpts) ? 150 : numpts	
	
	string window_name = ""
	sprintf window_name, "%s__differentiated", nameofwave(w)
	string wn = ""
	sprintf wn, "%s__diffx", nameofwave(w)	

	wave tempwave = Diffwave(w, numpts=numpts)

	dowindow/k $window_name
	display/N=$window_name
	appendimage tempwave
	ModifyImage tempwave ctab= {*,*,VioletOrangeYellow,0}
	TextBox/W=$window_name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 window_name	
	Label left, y_label
	Label bottom, x_label
	if (filenum > 0)
		string text
		sprintf text "Dat%d", filenum
		TextBox/W=$window_name/C/N=datnum/A=LT text
	endif
end


function/wave DiffWave(w, [numpts])
	wave w
	variable numpts
	
	numpts = paramisdefault(numpts) ? 150 : numpts
	
	duplicate/o w, tempwave
	print dimsize(w, 0)
	print ceil(dimsize(w,0)/numpts)
	resample/DIM=0 /down=(ceil(dimsize(w,0)/numpts)) tempwave
	differentiate/DIM=0 tempwave	
	return tempwave
end

function DisplayMultiple(datnums, name_of_wave, [diff, x_label, y_label])
// Plots data from each dat on same axes... Will differentiate first if diff = 1
	wave datnums
	string name_of_wave, x_label, y_label
	variable diff

	if (paramisDefault(x_label))
		struct ScanVars S
		scv_getLastScanVars(S)   
		x_label = S.x_label
	endif
	if (paramisDefault(y_label))
		struct ScanVars S2
		scv_getLastScanVars(S2)   
		y_label = S2.y_label
	endif

//	x_label = selectstring(paramisdefault(x_label), x_label, "")
//	y_label = selectstring(paramisdefault(y_label), y_label, "")

	string window_name
	sprintf window_name, "Dats%dto%d", datnums[0], datnums[numpnts(datnums)-1]
	dowindow/k $window_name
	display/N=$window_name
	TextBox/W=$window_name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 window_name	
	
	
	variable i = 0, datnum
	string wn
	string tempwn
	for(i=0; i < numpnts(datnums); i++)
		datnum = datnums[i]
		sprintf wn, "dat%d%s", datnum, name_of_wave
		sprintf tempwn, "tempwave_%s", wn
		duplicate/o $wn, $tempwn
		if (diff == 1)
			wave tempwave = diffwave($tempwn)
			duplicate /o tempwave $tempwn
			wave tempwave = $tempwn

		else 
			wave tempwave = $tempwn
		endif
		appendimage/W=$window_name tempwave
		ModifyImage/W=$window_name $tempwn ctab= {*,*,VioletOrangeYellow,0}
	endfor
	Label left, y_label
	Label bottom, x_label

end


function DisplayWave(w, [x_label, y_label])
	wave w
	string x_label, y_label
	
	x_label = selectstring(paramisdefault(x_label), x_label, "")
	y_label = selectstring(paramisdefault(y_label), y_label, "")
	
	string name, wn = nameofwave(w)
	sprintf name "%s_", wn
	
	svar sc_colormap
	dowindow/k $name
	display/N=$name
	setwindow kwTopWin, graphicsTech=0
	appendimage $wn
	modifyimage $wn ctab={*, *, $sc_ColorMap, 0}
//	colorscale /c/n=$sc_ColorMap /e/a=rc
	ColorScale/C/N=colorbar/A=RC/E image=$wn
	Label left, y_label
	Label bottom, x_label
	TextBox/W=$name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 name
	
end


function Display2DWaterfall(w, [x_label, y_label])
	wave w
	string x_label, y_label
	variable num_repeats = DimSize(w, 1)
	
	x_label = selectstring(paramisdefault(x_label), x_label, "")
	y_label = selectstring(paramisdefault(y_label), y_label, "")
	
	string name, wn = nameofwave(w)
	sprintf name "%s_", wn
	
	dowindow/k $name
	display/N=$name
	TextBox/W=$name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 name
	
//	Legend/C/N=text0/J/A=M
	
	variable i
	for(i = 0; i < num_repeats; i++)
       AppendToGraph/W=$name w[][i]
	endfor
	
//   Legend/C/N=text0/J/A=MC "\\s(dat187current_2d) repeat 1\r\\s(dat187current_2d#1) repeat 2\r\\s(dat187current_2d#2) repeat 3\r\\s(dat187current_2d#3) repeat 4";DelayUpdate
//   AppendText "\\s(dat187current_2d#4) repeat 5"
	Label/W=$name left y_label
	Label/W=$name bottom, x_label
	
	makecolorful()
	
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
			case 3:
				datstart = 337
				v1gmax = 2; v2gmax = 6; v3gmax = 4 //Have to make global to use NumVarOrDefault...
				v1start = 10; v2start = -200; v3start = -450
				v1step = 90; v2step = -20; v3step = -50
				make/o/t varlabels = {"Bias", "Nose", "Plunger"}
				make/o/t axislabels = {"CSS", "RC1"} //y, x
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

	abort "Can this use the ScanController Graphs stuff now?"

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


function TransitionCenterFromFit(w)
	wave w
	variable Vmid, smooth_width
	// Get rough middle from differentiating
	redimension/N=-1 w
	duplicate/FREE w wSmooth
	wavestats/Q/M=1 w //easy way to get num notNaNs (M=1 only calculates a few wavestats)
	smooth_width = V_npnts/10 //width to smooth by (relative to how many datapoints taken)
	smooth smooth_width, wSmooth	//Smooth wave so differentiate works better
	differentiate wSmooth /D=wSmoothDiff
	wavestats/Q/M=1 wSmoothDiff
	Vmid = V_minloc
	
	// Estimate fit parameters
	Make/D/O/N=5 W_coef
	wavestats/Q/M=1/R=[V_minRowLoc-V_npnts/5, V_minRowLoc+V_npnts/5] w //wavestats close to the transition (in mV, not dat points)
					//Amp,   			Const, 	Theta, 							Mid,	Linear
	w_coef[0] = {-(v_max-v_min), v_avg, 	abs((v_maxloc-v_minloc)/3), 	Vmid, 0}
	duplicate/O/Free w_coef w_coeftemp 
	
	// Fit with initial param guess
	funcFit/Q Chargetransition W_coef w 
	wave w_sigma
	variable scan_width = abs(rightx(w)-leftx(w))
	if(w_sigma[3] < scan_width/10) // Check Vmid was a good fit by seeing if uncertainty is <1/10 width of scan
		return w_coef[3]
	endif
	
	// Otherwise get a better guess of the linear component
	make/O/N=2 cm_coef = 0
	duplicate/O/Free/R=(leftx(w), vmid-scan_width/5) w wBeforeTransition //so hopefully just the gradient of the line leading up to the transition and not including the transition
	curvefit/Q line kwCWave = cm_coef wBeforeTransition /D
	
	// Fit again with better slope estimate
	w_coef = w_coeftemp
	w_coef[4] = cm_coef[1] // Slope
	funcFit/Q Chargetransition W_coef w	  //try again with new set of w_coef
	if	(w_sigma[3] < scan_width/10)
		return w_coef[3]
	else
		print "Bad Vmid = " + num2str(w_coef[3]) + " +- " + num2str(w_sigma[3]) + " near Vmid = " + num2str(Vmid)
		return NaN
	endif
end



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
	//CurveFitDialog/ w[0] = Amp
	//CurveFitDialog/ w[1] = Const
	//CurveFitDialog/ w[2] = Theta
	//CurveFitDialog/ w[3] = Mid
	//CurveFitDialog/ w[4] = Linear

	return w[0]*tanh((x - w[3])/(2*w[2])) + w[4]*x + w[1]
End

//function makechargetransitionfit()
//	make/o/n=(numpnts(FastScan)) temp_transitionfit
//	variable i
//	for (i = 0; i < numpnts(FastScan); i++)
//		temp_transitionfit[i] = Chargetransition(fit_FastScan,
//	endfor
//end



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




function udh5()
	// Loads HDF files back into Igor
	abort "This needs adapting so that it doesn't just load all files!"
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




function display_calibration_accuracy(w)
	wave w
	
	string new_wn = nameofwave(w)+"_accuracy"
	
	duplicate/o w $new_wn
	
	wave nw = $new_wn
	
	nw -= x
	display nw
	label bottom "Applied V /mV"
	label left "Difference from Nominal /mV"
end

function display_all_calibration()
	wave v1, v2, v3, v4
	display_calibration_accuracy(v1)
	display_calibration_accuracy(v2)
	display_calibration_accuracy(v3)
	display_calibration_accuracy(v4)	
end




//////////////////////////////////////////////////////////


function plot_differential_conductance(current_wave, [smoothing_factor, x_label, y_label])
	wave current_wave
	variable smoothing_factor
	string x_label, y_label
	
	x_label = selectstring(paramisdefault(x_label), x_label, "")
	y_label = selectstring(paramisdefault(y_label), y_label, "")
	smoothing_factor = paramisDefault(smoothing_factor) ? 1 : smoothing_factor

	string graph_name = "dIdVGraph"
	svar sc_colormap
	
	string wn = nameofwave(current_wave) + "_dIdV"
	duplicate/o current_wave $wn
	wave w = $wn
	variable smooth_num = round(smoothing_factor*DimSize(w, 0)/20)
	smooth/dim=0/E=3 smooth_num, w
	differentiate w
	w[,smooth_num] = NaN
	w[dimsize(w, 0)-smooth_num,] = NaN

	
	// Display the data
	KillWindow/z $graph_name
	display/k=1 /N=$graph_name

	setwindow kwTopWin, graphicsTech=0
	appendimage $wn
	modifyimage $wn ctab={*, *, $sc_ColorMap, 0}
	ColorScale/C/N=colorbar/A=RC/E image=$wn
	Label left, y_label
	Label bottom, x_label
	TextBox/W=$graph_name/C/N=textid/A=LT/X=1.00/Y=1.00/E=2 wn
//	setaxis bottom, $wn[x][smooth_num], *
	
end