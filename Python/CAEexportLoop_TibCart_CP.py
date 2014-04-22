# Execute using 'abaqus cae noGUI=scriptname.py'

import os
wdir = 'H:\\Northwestern-RIC\\Modeling\\Abaqus\\Subjects\\'
import glob
filList = glob.glob(wdir+'*\\*.fil')

from abaqus import *
from abaqusConstants import *
session.Viewport(name='Viewport: 1', origin=(0.0, 0.0), width=231.562508493662, 
    height=180.800009429455)
session.viewports['Viewport: 1'].makeCurrent()
session.viewports['Viewport: 1'].maximize()
from viewerModules import *
from driverUtils import executeOnCaeStartup
executeOnCaeStartup()

for filFilename in filList:
    (pathToFile, ext) = os.path.splitext(filFilename)
    odbpathname = pathToFile+'.odb'
    o2 = session.openOdb(name=odbpathname)
    session.viewports['Viewport: 1'].setValues(displayedObject=o2)
    odb = session.odbs[odbpathname]
    session.viewports['Viewport: 1'].view.setValues(nearPlane=362.511, 
        farPlane=485.407, width=46.5183, height=51.6998, viewOffsetX=-2.63997, 
        viewOffsetY=11.7813)
    session.View(name='User-1', nearPlane=362.51, farPlane=485.41, width=46.518, 
        height=51.7, projection=PERSPECTIVE, cameraPosition=(84.538, 434.99, 
        -79.692), cameraUpVector=(0.94138, -0.31794, 0.11273), cameraTarget=(
        82.784, 37.875, 72.702), viewOffsetX=-2.64, viewOffsetY=11.781, 
        autoFit=OFF)
    session.viewports['Viewport: 1'].odbDisplay.commonOptions.setValues(
        visibleEdges=NONE)
    session.viewports['Viewport: 1'].odbDisplay.display.setValues(plotState=(
        CONTOURS_ON_UNDEF, ))
    leaf = dgo.Leaf(leafType=DEFAULT_MODEL)
    session.viewports['Viewport: 1'].odbDisplay.displayGroup.remove(leaf=leaf)
    leaf = dgo.LeafFromElementSets(elementSets=('MTIBIACARTILAGE.MTIBIACARTILAGE', ))
    session.viewports['Viewport: 1'].odbDisplay.displayGroup.add(leaf=leaf)
    session.viewports['Viewport: 1'].odbDisplay.setPrimaryVariable(
        variableLabel='CPRESS', outputPosition=ELEMENT_NODAL)    
    rptname = pathToFile+'_CPRESS_MedTibCart.rpt'  
    session.fieldReportOptions.setValues(printMinMax=OFF, printTotal=OFF)
    for framenum in range(21):
        try:
            session.writeFieldReport(fileName=rptname, append=ON, 
                sortItem='Node Label', odb=odb, step=1, frame=framenum, 
                outputPosition=ELEMENT_NODAL, variable=(('CPRESS', ELEMENT_NODAL), ))
        except:
            print 'The analysis has not completed'
    #
    leaf = dgo.Leaf(leafType=DEFAULT_MODEL)
    session.viewports['Viewport: 1'].odbDisplay.displayGroup.remove(leaf=leaf)
    leaf = dgo.LeafFromElementSets(elementSets=('LTIBIACARTILAGE.LTIBIACARTILAGE', ))
    session.viewports['Viewport: 1'].odbDisplay.displayGroup.add(leaf=leaf)
    session.viewports['Viewport: 1'].odbDisplay.setPrimaryVariable(
        variableLabel='CPRESS', outputPosition=ELEMENT_NODAL)    
    rptname = pathToFile+'_CPRESS_LatTibCart.rpt'  
    session.fieldReportOptions.setValues(printMinMax=OFF, printTotal=OFF)
    for framenum in range(21):
        try:
            session.writeFieldReport(fileName=rptname, append=ON, 
                sortItem='Node Label', odb=odb, step=1, frame=framenum, 
                outputPosition=ELEMENT_NODAL, variable=(('CPRESS', ELEMENT_NODAL), ))
        except:
            print 'The analysis has not completed'
    session.odbs[odbpathname].close()
    #
    rptfile = open(pathToFile+'_CPRESS_MedTibCart.rpt')
    rptlist = rptfile.readlines()
    rptfile.close()
    os.remove(pathToFile+'_CPRESS_MedTibCart.rpt')
    rptlist2 = []
    for i in range(len(rptlist)):
        rptline = rptlist[i]
        rptsplit = rptline.split()
        if len(rptsplit) == 4:
            if rptsplit[3] != '0.':
                rptlist2.append(rptline)
        else:
            rptlist2.append(rptline)
    newrpt = []
    for i in range(len(rptlist2)):
        rptline = rptlist2[i]
        rptsplit = rptline.split()
        if len(rptsplit) == 4:
            if rptsplit[2:] != newrpt[-1].split()[2:]:
                newrpt.append(rptline)
        else:
            newrpt.append(rptline)        
    newrptfile = open(pathToFile+'_CPRESS_MedTibCart.rpt','w')
    newrptfile.writelines(newrpt)
    newrptfile.close()
    # 
    rptfile = open(pathToFile+'_CPRESS_LatTibCart.rpt')
    rptlist = rptfile.readlines()
    rptfile.close()
    os.remove(pathToFile+'_CPRESS_LatTibCart.rpt')
    rptlist2 = []
    for i in range(len(rptlist)):
        rptline = rptlist[i]
        rptsplit = rptline.split()
        if len(rptsplit) == 4:
            if rptsplit[3] != '0.':
                rptlist2.append(rptline)
        else:
            rptlist2.append(rptline)
    newrpt = []
    for i in range(len(rptlist2)):
        rptline = rptlist2[i]
        rptsplit = rptline.split()
        if len(rptsplit) == 4:
            if rptsplit[2:] != newrpt[-1].split()[2:]:
                newrpt.append(rptline)
        else:
            newrpt.append(rptline)        
    newrptfile = open(pathToFile+'_CPRESS_LatTibCart.rpt','w')
    newrptfile.writelines(newrpt)
    newrptfile.close()
