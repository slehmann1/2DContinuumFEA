
# Finite Element Solver For 2D Planar Continuum Meshes
#### A simplified FEA solver using quadrilateral elements
### Overview
A 2D quadrilateral mesher and solver for plane strain or plane stress problems. The program is validated with a classical problem of a rectangular plate with a hole in it. The results are found to align with both Abaqus and classical solutions.

Currently the only boundary condition supported is fixed nodes. It would be easy to extend this program to add additional cases. The program is designed to be simple and lightweight; more advanced programs are available for solving challenging problems. A significant shortcoming of this program is its simplified meshing approach; local results in commercial software such as Abaqus yield more accurate results.

**Sample Problem Mesh And Displacement Plot**
<p align="center">
  <img src="https://github.com/slehmann1/2DContinuumFEA/blob/main/res/DeflectionResults.png?raw=true" alt="Displacement Plot"/>
</p>

**Reference Abaqus Mesh And Displacement Plot**
<p align="center">
  <img src="https://github.com/slehmann1/2DContinuumFEA/blob/main/res/AbaqusDeflectionResults.png?raw=true" alt="Abaqus Displacement Plot"/>
</p>

**Sample Problem Von Mises Stresses**
<p align="center">
  <img src="https://github.com/slehmann1/2DContinuumFEA/blob/main/res/VonMisesResults.png?raw=true" alt="Displacement Plot"/>
</p>

**Reference Abaqus Von Mises Stresses**
<p align="center">
  <img src="https://github.com/slehmann1/2DContinuumFEA/blob/main/res/AbaqusVonMisesResults.png?raw=true" alt="Abaqus Displacement Plot"/>
</p>

Note the stress discontinuities around the hole of the Matlab solution due to poor meshing. However, global results align closely.

#### Dependencies
Written in Matlab
