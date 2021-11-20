//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Other Functions///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AAOtherFunctions()
end


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


function/wave Linspace(start, fin, num)
	// To use this in command line:
	//		make/o/n=num tempwave
	// 		tempwave = linspace(start, fin, num)[p]
	//
	// To use in a function: 
	//		wave tempwave = linspace(start, fin, num)  //Can be done ONCE (each linspace overwrites itself!)
	//	or 
	//		make/n=num tempwave = linspace(start, fin, num)[p]  //Can be done MANY times
	//
	// To combine linspaces:
	//		make/free/o/n=num1 w1 = linspace(start1, fin1, num1)[p]
	//		make/free/o/n=num2 w2 = linspace(start2, fin2, num2)[p]
	//		concatenate/np/o {w1, w2}, tempwave
	//
	variable start, fin, num
	Make/N=2/O/Free linspace_start_end = {start, fin}
	Interpolate2/T=1/N=(num)/Y=linspaced linspace_start_end
	return linspaced
end

function test_func()

//	wave tempwave_test = linspace(0, 100, 21)
	make/o/free/n=5 w1 = linspace(0, 10, 5)[p]
	make/o/free/n=5 w2 = linspace(20, 50, 5)[p]
	concatenate/np/o {w1, w2}, tempwave_test
	print tempwave_test

end