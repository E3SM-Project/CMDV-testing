#! /usr/bin/env python

import matplotlib.pyplot as plt
from math import sqrt, exp, log, pi
import numpy

########################################################################

def plot_mode(ax, magnitude, median, std_dev, label):
    """
    Plot the mode of an aerosol distribution

    Arguments:
        ax
        magnitude
        median
        std_dev
    """
    #D = numpy.logspace(log(10**-20), log(10**-13), 101)
    lnD = numpy.linspace(-20, -13, 101)
    m = magnitude / (sqrt(2 * pi * log(std_dev))) * \
                     numpy.exp(-(lnD - log(median))**2 /
                               (2 * log(std_dev)**2))
    mode = ax.plot(lnD, m, label=label)

########################################################################

def plot_single_mode(magnitude, median, std_dev, label):
    """
    Plot a single mode of an aerosol distribution

    Arguments:
        magnitude
        median
        std_dev
    """
    fig, ax  = plt.subplots(1, 1, figsize=(10,4.5))
    plot_mode(ax, magnitude, median, std_dev, label)
    ax.set_title("Aerosol Mode")
    ax.set_xlabel("Natural Log of Particle Diameter, m")
    ax.set_ylabel("Number Concentration")
    ax.legend()

########################################################################

def plot_three_modes(aiken, accum, pca):
    """
    Plot a single mode of an aerosol distribution

    Arguments:
        magnitude
        median
        std_dev
    """
    fig, ax  = plt.subplots(1, 1, figsize=(10,4.5))
    for mode in (aiken, accum, pca):
        plot_mode(ax, *mode)
    ax.set_title("Aerosol Modes")
    ax.set_xlabel("Natural Log of Particle Diameter, m")
    ax.set_ylabel("Number Concentration")
    ax.legend()
    plt.show()
