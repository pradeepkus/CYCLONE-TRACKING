# CYCLONE-TRACKING

This repository contains a robust algorithm for cyclone detection and tracking, originally developed in NCL (NCAR Command Language) for mid-troposphere cyclone analysis. The algorithm is versatile and can be applied to track a wide variety of atmospheric systems, including cyclones, low-pressure systems, and other tropical disturbances, as long as the relevant fields are used where these systems appear as local maxima or minima at a single pressure level.

The method is highly accurate and has been validated against manually tracked cyclone datasets, ensuring reliability for both research and operational applications. Users can apply this algorithm to different meteorological fields such as pressure, geopotential height, or vorticity, depending on the type of system they wish to study.

## Key Features
- Detection and tracking of cyclones and low-pressure systems at multiple atmospheric levels  
- Flexibility to identify systems represented as either maxima or minima in atmospheric fields  
- Validation against manual tracking data for improved accuracy  
- Originally implemented in NCL, with plans to expand the implementation to Python and other programming languages for broader accessibility  
- Easy integration with observational or model datasets  

This tool is intended for researchers and meteorologists who need a reliable and automated method for analyzing cyclones and other dynamic atmospheric systems.

---

## Example: Tracking Accuracy

The accuracy of the method is demonstrated below for **Cyclone Index = 39**, which corresponds to the June 1998 cyclone.  
The tracking algorithm captured a track length of **37 time steps**, starting on **1998-06-01 18:00 UTC** and ending on **1998-06-10 18:00 UTC**.  

![Cyclone Track with Vorticity](figures/cyclone_track_labeled.png)
