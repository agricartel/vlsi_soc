#  Skywater 130nm PDK with Synopsys Toolchain
##  Building Synopsys Files for Skywater 130nm
This guide provides instructions on building the supporting files to use the Skywater 130nm PDK in Synopsys Design Compiler and ICC2.
### Patching the PDK
Make sure the `synopsys-changes.patch` file is in your working directory.
```bash
git clone https://github.com/google/skywater-pdk.git
cp ./synopsys-changes.patch ./skywater-pdk/
cd ./skywater-pdk/
git apply synopsys-changes.patch
```

### Building the PDK
Follow the instructions in `vendor/synopsys/README.md`:
```bash
git submodule update --init libraries/sky130_fd_sc_hd/latest
make sky130_fd_sc_hd
cd vendor/synopsys
make sky130_fd_sc_hd_db
make sky130_fd_sc_hd_mw
make sky130_fd_sc_hd_ndm
make tluplus
```
Resulting files are saved to `vendor/synopsys/results/`.

##  Using the PDK with Synopsys DC and ICC2
See the included example scripts for file paths in the PDK.
