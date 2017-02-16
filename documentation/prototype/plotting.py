#! /usr/bin/env python

import netCDF4
import matplotlib.pyplot as plt

def plot_geopotential(time=0):
    swtc1 = netCDF4.Dataset("swtc1/movies/swtc11.nc", "r")
    times = swtc1.variables["time"][:]
    lat   = swtc1.variables["lat"][:]
    lon   = swtc1.variables["lon"][:]
    geop  = swtc1.variables["geop"][:,0,:,:]
    fig, ax  = plt.subplots(1, 1, figsize=(10,5))
    contours = ax.contourf(lon, lat, geop[time])
    cbar     = fig.colorbar(contours)
    ax.set_title("Geopotential at t = %d days" % times[time])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_aspect("equal")
