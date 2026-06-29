# IRS/RIS-Aided Indoor Visible Light Communication Simulation Framework

## Overview
This work provides a framework for indoor Intelligent Reconfigurable Surface-aided VLC systems.

External/self-blockage, randomly generated scenarios, Laplace-distribution-based receiver orientation, wall/RIS-assisted reflected NLoS links, SCA non-convex algorithm and RIS optimisation considered.

This modell is inspired by S. Aboagye,etc. "Intelligent Reflecting Surface-Aided Indoor Visible Light Communication Systems,", doi: 10.1109/LCOMM.2021.3114594.

## File structure
"params.m" // All the parameters

"sca_optimize.m" // SCA non-convex optimise algorithm

"plot_sca_convergence.m" // Figure generation: The SCA algorithm iteratively approximates the global optimal solution

"generate_scenario.m" // Generate random scenes of the user's location, the number and location of obstructions, and the orientation of the device

"cos_irradiance.m"

"cos_incidence_from.m"

"segment_cylinder_intersect.m"

"concentrator_gain.m"


## run the simulation & Output figures

'SCA Convergence' by "plot_sca_convergence.m", running code at the bottom

## Notes

contact: 1270361675@qq.com
