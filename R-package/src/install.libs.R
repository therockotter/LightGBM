# User options
use_precompile <- FALSE
use_gpu <- FALSE
use_mingw <- FALSE

# Check for precompilation
if (!use_precompile) {

  # Check repository content
  source_dir <- file.path(R_PACKAGE_SOURCE, "src", fsep = "/")
  setwd(source_dir)
  
  if (!file.exists("_IS_FULL_PACKAGE")) {
    if (!file.copy("./../../include", "./", overwrite = TRUE, recursive = TRUE)) {
      stop("Cannot find folder LightGBM/include")
    }
    if (!file.copy("./../../src", "./", overwrite = TRUE, recursive = TRUE)) {
      stop("Cannot find folder LightGBM/src")
    }
    if (use_gpu) {
      if (!file.copy("./../../compute", "./", overwrite = TRUE, recursive = TRUE)) {
        print("Cannot find folder LightGBM/compute, disabling GPU build.")
        use_gpu <- FALSE
      }
    }
    if (!file.copy("./../../CMakeLists.txt", "./", overwrite = TRUE, recursive = TRUE)) {
  	  stop("Cannot find file LightGBM/CMakeLists.txt")
    }
  }
  
  # Prepare building package
  build_dir <- file.path(source_dir, "build", fsep = "/")
  dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
  setwd(build_dir)
  
  # Prepare installation steps
  cmake_cmd <- "cmake"
  build_cmd <- "make -j4"
  lib_folder <- file.path(R_PACKAGE_SOURCE, "src", fsep = "/")
  
  # Check if Windows installation (for gcc vs Visual Studio)
  if (WINDOWS) {
    if (use_mingw) {
      cmake_cmd <- paste0(cmake_cmd, " -G \"MinGW Makefiles\" ")
      build_cmd <- "mingw32-make.exe -j4"
    } else {
      cmake_cmd <- paste0(cmake_cmd, " -DCMAKE_GENERATOR_PLATFORM=x64 ")
      build_cmd <- "cmake --build . --target _lightgbm  --config Release"
      lib_folder <- file.path(R_PACKAGE_SOURCE, "src/Release", fsep = "/")
    }
  }
  
  if (use_gpu) {
    cmake_cmd <- paste0(cmake_cmd, " -DUSE_GPU=1 ")
  }
  
  # Install
  system(paste0(cmake_cmd, " .."))
  system(build_cmd)
  src <- file.path(lib_folder, paste0("lib_lightgbm", SHLIB_EXT), fsep = "/")
  
} else {

  # Has precompiled package
  lib_folder <- file.path(R_PACKAGE_SOURCE, "../", fsep = "/")
  if (file.exists(file.path(lib_folder, paste0("lib_lightgbm", SHLIB_EXT), fsep = "/"))) {
    src <- file.path(lib_folder, paste0("lib_lightgbm", SHLIB_EXT), fsep = "/")
  } else if (file.exists(file.path(lib_folder, paste0("Release/lib_lightgbm", SHLIB_EXT), fsep = "/"))) {
    src <- file.path(lib_folder, paste0("Release/lib_lightgbm", SHLIB_EXT), fsep = "/") 
  } else {
    src <- file.path(lib_folder, paste0("/windows/x64/DLL/lib_lightgbm", SHLIB_EXT), fsep = "/") # Expected result: installation will fail if it is not here or any other
  }
  
}

# Check installation correctness
dest <- file.path(R_PACKAGE_DIR, paste0("libs", R_ARCH), fsep = "/")
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
if (file.exists(src)) {
  cat("Found library file: ", src, " to move to ", dest, sep = "")
  file.copy(src, dest, overwrite = TRUE)
} else {
  stop(paste0("Cannot find lib_lightgbm", SHLIB_EXT))
}
