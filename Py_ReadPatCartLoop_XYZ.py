import os
import glob
import re


wdir = 'H:\\Northwestern-RIC\\Modeling\\Abaqus\\'

pcfile = open(wdir+'GenericFiles\\Nodes_PATELLACARTILAGE.data')
pclist = pcfile.readlines()
pcfile.close()

node_num = []; node_xyz = []
for i in range(len(pclist)):
    pcline = pclist[i]
    node_num.append(pcline.split(',',1)[0].strip())
    node_xyz.append(pcline.split(',',1)[1].strip())
node2xyz = dict(zip(node_num,node_xyz))
    
rptfilepath = wdir+'*\\*\\*CPRESS*Pat*.rpt'
import glob
rptfilelist = glob.glob(rptfilepath)

import re

for rptfilename in rptfilelist:

    rptfile = open(rptfilename)
    rptlist = rptfile.readlines()
    rptfile.close()   

    start = []; end = []; stime = []
    for i in range(len(rptlist)):
        rptline = rptlist[i]
        if rptline == '-----------------------------------------------------------------\n':
            start.append(i+1)
        elif rptline == '********************************************************************************\n':
            if i != 0:
                end.append(i-3)
        elif len(re.findall('Step Time = ',rptline)) > 0:
            stime.append(rptline.split()[-1])
    end.append(len(rptlist)-3)

    output = []
    output.append('Time\tX\tY\tZ\tCPress\n')
    for i in range(len(stime)):        
        for j in range(start[i],end[i]+1):
            node = rptlist[j].split()[2]
            xyz = node2xyz[node]
            x = xyz.split(',')[0].strip()
            y = xyz.split(',')[1].strip()
            z = xyz.split(',')[2].strip()
            cp = rptlist[j].split()[-1].strip()
            output.append(stime[i]+'\t'+x+'\t'+y+'\t'+z+'\t'+cp+'\n')
            
    outrptfile = open(rptfilename[:-4]+'.data','w')
    outrptfile.writelines(output)
    outrptfile.close()
    
