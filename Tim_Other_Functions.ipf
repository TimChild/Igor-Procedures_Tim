//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Other Functions///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAOtherFunctions()
end


////// JSON General //////


function print_keys(jsonID, path)
	variable jsonID
	string path
	wave/t ans = JSON_getkeys(jsonID, path)
	print ans
end




/////////////////////////////

structure sc_global_vars // NOTE: Still have to declare as nvar etc when using ... so defeats the purpose really...
	// Structure to make accessing common sc global variables easier and cleaner

	// USE STRUCTFILL!! 
	//	StructFill

   nvar sc_is2d, sc_startx, sc_starty, sc_finx, sc_finy, sc_numptsx, sc_numptsy
   nvar sc_abortsweep, sc_pause, sc_scanstarttime
   wave fadcattr
   wave/T fdacvalstr, facdvalstr
endstructure


function saveLogsOnly([msg, save_experiment])
	string msg
	variable save_experiment // Default: Do not save experiment for just this
	
	nvar filenum
	
	if (paramisdefault(msg))
		msg = "SaveLogsOnly"
	endif
	
	initSaveFiles(msg=msg, logs_only=1) // Saves logs here, and adds Logs_Only attr to root group of HDF	
	closeSaveFiles()	
	// increment filenum
	filenum+=1

	nvar sc_save_time
	if(save_experiment==1 & (datetime-sc_save_time)>60)
		// save if sc_saveexperiment=1
		// and if more than 1 minutes has elapsed since previous saveExp
		// if the sweep was aborted sc_saveexperiment=0 before you get here
		saveExp()
		sc_save_time = datetime
	endif
	
	// check if a path is defined to backup data
	if(sc_checkBackup())
		// copy data to server mount point
		sc_copyNewFiles(filenum, save_experiment=save_experiment)
	endif
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


function print_eta(S)
	// Useful to put in 2D babydac scans which can be long. Will print an eta
	struct BD_ScanVars &S
	variable eta
	Eta = (S.delayx+0.08)*S.numptsx*S.numptsy+S.delayy*S.numptsy+S.numptsy*abs(S.finx-S.startx)/(S.rampratex/3)  //0.06 for time to measure from lockins etc, Ramprate/3 because it is wrong otherwise
	Print "Estimated time for scan = " + num2str(eta/60) + "mins, ETA = " + secs2time(datetime+eta, 0)	
end
	
	
//	// Check sum of sampleLens isn't going to be longer than 1s
//	if(sum(samples)/measureFreq > 1) // If period of wave is greater than 1s warn  // TODO: Make this actually sum just the sampleLens then * by measureFreq (or sampleFreq?)
//		printf "WARNING[fdAWG_check_AW]: Period of AW is %.1fs, continuing anyway"
//	endif