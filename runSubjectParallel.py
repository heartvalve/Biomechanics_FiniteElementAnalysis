"""
----------------------------------------------------------------------
    runSubjectParallel.py
----------------------------------------------------------------------
    This program can be used to run multiple FEA simulations
    simultaneously, split over multiple processors. Each simulation
    uses only one CPU.

    Input:
        Subject ID
    Output:
        Simulation results
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2014-02-11
----------------------------------------------------------------------
"""


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID list
subIDs = ['20130401CONM']
# ####################################################################


# Imports
import os
import glob
import time
from datetime import datetime
from multiprocessing import Pool

from feaSimulation import *


def runParallel(simName):
    """
    Picklable(?) function for running FEA simulations in parallel.
    """ 
    # FEA Simulation
    fSim = feaSimulation(simName)
    fSim.run()
    # Wait
    time.sleep(10)
    return None

# ####################################################################

class runSubject:
    """
    A class to run all of the FEA simulations for a given subject.
    """

    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID and add
        the subject directory and starting time.
        """
        # Subject ID
        self.subID = subID
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        #self.subDir = os.path.join(nuDir,'Modeling','Abaqus','Subjects',subID)+'\\'
        self.subDir = os.path.join(nuDir,'SVN','Working','FiniteElement','Subjects',subID)+'\\'
        # Subroutine directory
        self.userDir = os.path.join(nuDir,'SVN','Working','FiniteElement','UserSubroutines')+'\\'
        # Starting time
        self.startTime = datetime.now()

    """------------------------------------------------------------"""
    def getSimNames(self):
        """
        Get all of the simulation names for the subject.
        """
        # Simulation names in directory
        simNames = glob.glob(self.subDir+self.subID+'*.inp')
        for (i,tN) in enumerate(simNames):
            simNames[i] = os.path.basename(tN).split('.')[0]
        return simNames

    """------------------------------------------------------------"""
    def displayMessage(self):
        """
        Display the amount of time elapsed from the creation of the
        class instance.
        """
        timeDiff = datetime(1,1,1) + (datetime.now()-self.startTime)
        if timeDiff.hour < 1:
            print (self.subID+' is finished -- elapsed time is %d minutes.' %(timeDiff.minute))
        else:
            print (self.subID+' is finished -- elapsed time is %d hour(s) and %d minute(s).' %(timeDiff.hour, timeDiff.minute))

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run all of the simulations for a given subject.
        """       
        # Simulation names
        simNames = self.getSimNames()
        # Start worker pool
        pool = Pool(processes=2)
        # Run parallel processes
        pool.map(runParallel, simNames)
        # Clean up spawned processes
        pool.close()
        pool.join()
        # Display message to user
        self.displayMessage()


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runSub = runSubject(subID)
        # Run code
        runSub.run()
