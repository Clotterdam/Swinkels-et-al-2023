dir = getDirectory("Choose the Directory");
File.makeDirectory(dir+"ResultsColoc");
oriname = getTitle();

membranechannel = 2;		//Channel for membrane stain (e.g. alpha-tubulin)
granularchannel = 1;		//Channel for second, granular stain (e.g. VWF)
thirdchannel =3;			//Channel for third granular stain (e.g. VWFpp)
	
nROI = roiManager("count");
if (nROI>0) {
	roiManager("select all");
	roiManager("delete");
		}

//Segmentation of individual platelets based on membrane staining		
Title = getTitle();
run("Duplicate...", "duplicate channels="+membranechannel);
dupmem = getTitle();
run("Z Project...", "projection=[Average Intensity]");
avgmem = getTitle();
setAutoThreshold("Li dark");
run("Convert to Mask");
maskmem = getTitle();
run("Options...", "iterations=2 count=1 black do=Dilate");
run("Options...", "iterations=1 count=1 black do=[Fill Holes]");
run("Options...", "iterations=2 count=1 black do=Erode");
run("Watershed");
setThreshold(255, 255);
makeRectangle(3, 3, 1898, 1894);
run("Crop");
run("Analyze Particles...", "size=1000-16000 pixel circularity=0.2-1.00 exclude clear include add");
close(dupmem);
close(avgmem);
close(maskmem);
nROI = roiManager("count");
for(i=0;i<nROI;i++){
	roiManager("select", i);
	roiManager("translate", 3, 3);		
		}
run("Select None");
	

//Loop over ROIs and calculate colocalization within each platelet
//A montage is used to calculate colocalisation over several Z-slices
for (i = 0; i < nROI; i++) {
    // Get ROI and select it
    roiManager("select", i);
	//Handselect brightest 6 slices
    run("Duplicate...", "duplicate slices=23-28");
    rename("Dup");
    run("Make Montage...", "columns=8 rows=1 scale=1");
    rename("Montage");
    run("Split Channels");
     

    // Calculate colocalization using Colocalization Threshold 
    run("Colocalization Threshold", "channel_1=[C1-Montage] channel_2=[C3-Montage] use=None channel=[Red : Green] include");
   
	           
      close("C1-Montage");
      close("C2-Montage");
      close("C3-Montage");
      close("Dup");
   
    }
    selectWindow("Results");
	saveAs("Text", dir+"ResultsColoc\\"+oriname+".txt");
	close("Results");


		