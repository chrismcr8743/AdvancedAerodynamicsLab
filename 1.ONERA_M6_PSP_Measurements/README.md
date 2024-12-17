# Pressure-Sensitive Paint (PSP) Analysis on ONERA M6 Wing

## Description
This MATLAB script processes and analyzes **Pressure-Sensitive Paint (PSP)** data for surface pressure measurements on the ONERA M6 wing. It generates:
1. **Calibrated Pressure Contour Plots** for each test condition.
2. **Pressure Coefficient (Cp) Maps** for flow visualization.
3. **Spanwise Pressure Profiles** at selected stations for comparison.

The script reads `.tif` files containing PSP data, calibrates coordinates to physical dimensions, and computes aerodynamic parameters such as the **Pressure Coefficient (Cp)**.

---

## Requirements
- **MATLAB** (tested with version R2023a or newer)
- PSP data in `.tif` format
- Files must follow the naming convention: `V[velocity_ft_s]_[AoA]deg.tif`  
   Example: `V200_0deg.tif` (Velocity = 200 ft/s, Angle of Attack = 0°)

---

## Inputs
1. **PSP Data Files**: Located in the `ONERA_M6_Surface_Pressure_Data/` folder.
2. **Physical Parameters**:
   - Chord Length: `101.6 mm`
   - Span Length: `152.4 mm`
   - Air Density: `1.225 kg/m³`

---

## Outputs

### 1. Calibrated PSP Images
The calibrated PSP images show the spanwise and chordwise pressure distribution on the ONERA M6 wing.

![Calibrated PSP Image](images/example_Cp_plot.png)

---

### 2. Pressure Coefficient (Cp) Maps
The Pressure Coefficient (Cp) maps illustrate flow behavior and surface pressure variations.

![Pressure Coefficient Map](images/example_Cp_map.png)

---

### 3. Pressure Profiles at Spanwise Stations
Pressure profiles are generated at specific non-dimensional spanwise locations \( x/b \): [0.2, 0.44, 0.6, 0.8, 0.9].

![Spanwise Pressure Profiles](images/spanwise_pressure_profile.png)

---

## Usage
1. Clone or download this repository:
   ```bash
   git clone https://github.com/yourusername/ONERA_M6_Wing_PSP.git
   cd ONERA_M6_Wing_PSP
