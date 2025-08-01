cmake_minimum_required(VERSION 3.16)

# Strictly speaking in-source will work but will be very messy so it is not supported.
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
    message(FATAL_ERROR "In-source builds are not supported! Please use out of source builds:\n"
        "$ cd content\n"
        "$ rm CMakeCache.txt\n"
        "$ cd build\n"
        "$ cmake ../\n"
        "$ make -j4"
    )
endif()

# Inspired and referenced from https://blog.kitware.com/cmake-and-the-default-build-type
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
        "MinSizeRel" "RelWithDebInfo")
endif()

project(scap-security-guide NONE)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

# This is set to silence GNUInstallDirs warning about no language being used with cmake.
set(CMAKE_INSTALL_LIBDIR "/nowhere")
include(GNUInstallDirs)
include(CMakeDependentOption)
include(FindOpenSCAP)
include(FindPythonModule)
include(SSGCommon)

# Define Version values
set(SSG_MAJOR_VERSION 0)
set(SSG_MINOR_VERSION 1)
set(SSG_PATCH_VERSION 78)
set(SSG_VERSION "${SSG_MAJOR_VERSION}.${SSG_MINOR_VERSION}.${SSG_PATCH_VERSION}")

set(SSG_TARGET_OVAL_MAJOR_VERSION "5" CACHE STRING "Which major version of OVAL are we targetting. Only 5 is supported at the moment.")
set(SSG_TARGET_OVAL_MINOR_VERSION "11" CACHE STRING "Which minor version of OVAL are we targetting. Only 11 is supported at the moment.")
set(SSG_TARGET_OVAL_VERSION "${SSG_TARGET_OVAL_MAJOR_VERSION}.${SSG_TARGET_OVAL_MINOR_VERSION}")
set(SSG_VENDOR "ssgproject" CACHE STRING "Specify the XCCDF 1.2 vendor string.")

# Define Install Directories, where built content will be stored.
set(SSG_ANSIBLE_ROLE_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/scap-security-guide/ansible")
set(SSG_ANSIBLE_PER_RULE_PLAYBOOKS_INSTALL_DIR "${SSG_ANSIBLE_ROLE_INSTALL_DIR}/rule_playbooks")
set(SSG_BASH_ROLE_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/scap-security-guide/bash")
set(SSG_CONTENT_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/xml/scap/ssg/content")
set(SSG_GUIDE_INSTALL_DIR "${CMAKE_INSTALL_DOCDIR}/guides")
set(SSG_KICKSTART_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/scap-security-guide/kickstart")
set(SSG_TABLE_INSTALL_DIR "${CMAKE_INSTALL_DOCDIR}/tables")
set(SSG_TAILORING_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/scap-security-guide/tailoring")

# Define Source Directories, which will be used during the build.
set(SSG_BUILD_SCRIPTS "${CMAKE_SOURCE_DIR}/build-scripts")
set(SSG_JINJA2_CACHE_DIR "${CMAKE_BINARY_DIR}/jinja2_cache" CACHE PATH "Where the jinja2 cached bytecode should be stored. This speeds up builds at the expense of disk space. You can use one location for multiple SSG builds for performance improvements.")
set(SSG_SHARED "${CMAKE_SOURCE_DIR}/shared")
set(SSG_SHARED_REFS "${SSG_SHARED}/references")
set(SSG_SHARED_TRANSFORMS "${SSG_SHARED}/transforms")
set(SSG_UTILS_SCRIPTS "${CMAKE_SOURCE_DIR}/utils")

# Content Generation Opetions
option(SSG_ANSIBLE_PLAYBOOKS_ENABLED "If enabled, Ansible Playbooks for each profile will be built and installed." TRUE)
option(SSG_ANSIBLE_PLAYBOOKS_PER_RULE_ENABLED "If enabled, Ansible Playbooks for each rule will be built and installed." FALSE)
option(SSG_BASH_SCRIPTS_ENABLED "If enabled, Bash remediation scripts for each profile will be built and installed." TRUE)
option(SSG_BUILD_DISA_DELTA_FILES "If enabled, If the product has automated content from DISA for its STIG a tailoring file will be created with rules not covered by DISA's content enabled." TRUE)
option(SSG_JINJA2_CACHE_ENABLED "If enabled, the jinja2 templating files will be cached into bytecode. Also see SSG_JINJA2_CACHE_DIR." TRUE)
option(SSG_SCE_ENABLED "If enabled, additional SCE audit content will be enabled alongside OVAL-based auditing." FALSE)
option(SSG_SRG_XLSX_EXPORT "If enabled, an XLSX of SRG Export will be ceated." FALSE)
option(SSG_SEPARATE_SCAP_FILES_ENABLED "If enabled, separate SCAP files (OVAL, XCCDF, CPE dict, ...) will be installed alongside the source data-streams" TRUE)
option(SSG_BUILT_TESTS_ENABLED "If enabled, Automatus tests will be built" FALSE)
# Validation Options
option(SSG_BATS_TESTS_ENABLED "If enabled, bats will be used to run unit-tests of bash remediations." TRUE)
option(SSG_LINKCHECKER_VALIDATION_ENABLED "If enabled, linkchecker will be used to validate URLs in all the HTML guides and tables." TRUE)
option(SSG_SCAP_VALIDATION_ENABLED "If enabled, CTest tests will contain validation of built SCAP content. This is very time consuming." TRUE)
option(SSG_OVAL_SCHEMATRON_VALIDATION_ENABLED "If enabled, schematron validation will be performed as part of the ctest tests. Schematron takes a lot of time to complete but can find more issues than just plain XSD validation." TRUE)
option(SSG_SHELLCHECK_BASH_FIXES_VALIDATION_ENABLED "If enabled, shellcheck validation of bash fixes will be performed as part of the ctest tests." TRUE)
option(ENABLE_SCAPVAL13 "Set to ON to enable SCAPVal tests" OFF)
option(FORCE_VALIDATE_EVERYTHING "If enabled, perform all validation tests regardless of oscap version requirements. By default, the build system may not perform validation of some content types if the openscap used to build it is not up-to-date" FALSE)
option(ENABLE_CHECK_RULE_REMOVAL "If enabled, during ctest opted in products will be checked for rules that are present in the old release but not in the current one." FALSE)

# SSG_PRODUCT_DEFAULT modifies the behavior of all other options. Products which should be built
# by default should use the value ${SSG_PRODUCT_DEFAULT} instead of the boolean True. This allows
# us to disable all default products by passing `-DSSG_PRODUCT_DEFAULT=OFF` and then manually
# specifying a list of products to build.
option(SSG_PRODUCT_DEFAULT "If enabled, all default release products will be built; otherwise only explicitly enabled products will be" TRUE)

# Products to build content for. These generally correspond to directories in the root of this
# project. Note that the example product is always disabled unless explicitly asked for.
option(SSG_PRODUCT_AL2023 "If enabled, the Amazon Linux 2023 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_ALINUX2 "If enabled, the Alibaba Cloud Linux 2 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_ALINUX3 "If enabled, the Alibaba Cloud Linux 3 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_ALMALINUX9 "If enabled, the AlmaLinux OS 9 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_ANOLIS8 "If enabled, the Anolis OS 8 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_ANOLIS23 "If enabled, the Anolis OS 23 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_CHROMIUM "If enabled, the Chromium SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_DEBIAN11 "If enabled, the Debian 11 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_DEBIAN12 "If enabled, the Debian 12 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_DEBIAN13 "If enabled, the Debian 13 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_EKS "If enabled, the EKS SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_EXAMPLE "If enabled, the Example SCAP content will be built" FALSE)
option(SSG_PRODUCT_FEDORA "If enabled, the Fedora SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_FIREFOX "If enabled, the Firefox SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_KYLINSERVER10 "If enabled, the Kylin Server V10 content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OCP4 "If enabled, the OCP4 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OL7 "If enabled, the Oracle Linux 7 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OL8 "If enabled, the Oracle Linux 8 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OL9 "If enabled, the Oracle Linux 9 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OL10 "If enabled, the Oracle Linux 10 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OPENEMBEDDED "If enabled, the OpenEmbedded SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OPENEULER2203 "If enabled, the openEuler 22.03 LTS content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_OPENSUSE "If enabled, the openSUSE SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_RHCOS4 "If enabled, the RHCOS4 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_RHEL8 "If enabled, the RHEL8 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_RHEL9 "If enabled, the RHEL9 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_RHEL10 "If enabled, the RHEL10 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_RHV4 "If enabled, the RHV4 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_SLE12 "If enabled, the SLE12 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_SLE15 "If enabled, the SLE15 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_SLMICRO5 "If enabled, the SLE Micro 5 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_SLMICRO6 "If enabled, the SLE Micro 6 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_TENCENTOS4 "If enabled, the TencentOS Server 4 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_UBUNTU2204 "If enabled, the Ubuntu 22.04 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
option(SSG_PRODUCT_UBUNTU2404 "If enabled, the Ubuntu 24.04 SCAP content will be built" ${SSG_PRODUCT_DEFAULT})
# Products derivatives
option(SSG_CENTOS_DERIVATIVES_ENABLED "If enabled, CentOS derivative content will be built from the RHEL content" TRUE)

if("$ENV{PYTHONPATH}" STREQUAL "")
    set(ENV{PYTHONPATH} "${PROJECT_SOURCE_DIR}")
else()
    set(ENV{PYTHONPATH} "${PROJECT_SOURCE_DIR}:$ENV{PYTHONPATH}")
endif()
message(STATUS "PYTHONPATH: $ENV{PYTHONPATH}")

# Required Packages
set(Python_FIND_UNVERSIONED_NAMES FIRST)
find_package(Python REQUIRED)
find_package(OpenSCAP REQUIRED)

find_program(ANSIBLE_LINT_EXECUTABLE NAMES ansible-lint)
find_program(ANSIBLE_PLAYBOOK_EXECUTABLE NAMES ansible-playbook)
find_program(BATS_EXECUTABLE NAMES bats)
find_program(GIT_EXECUTABLE NAMES git)
find_program(GREP_EXECUTABLE NAMES grep)
find_program(LINKCHECKER_EXECUTABLE NAMES linkchecker)
find_program(SED_EXECUTABLE NAMES sed REQUIRED)
find_program(SHELLCHECK_EXECUTABLE NAMES shellcheck)
find_program(XMLLINT_EXECUTABLE NAMES xmllint REQUIRED)
find_program(XSLTPROC_EXECUTABLE NAMES xsltproc REQUIRED)
find_program(YAMLLINT_EXECUTABLE NAMES yamllint)

if(SSG_PRODUCT_RHEL9 OR SSG_PRODUCT_RHEL10 OR SSG_PRODUCT_UBUNTU2004 OR SSG_PRODUCT_UBUNTU2204 OR SSG_PRODUCT_UBUNTU2404)
set(SSG_SCE_ENABLED ON)
endif()

message(STATUS "")
message(STATUS "SCAP Security Guide ${SSG_VERSION}")
message(STATUS "(see ${CMAKE_SOURCE_DIR}/docs/manual/developer_guide.adoc for build instructions)")

message(STATUS "")
message(STATUS "Finding Python Modules:")
find_python_module(jinja2 REQUIRED)
find_python_module(yaml REQUIRED)
find_python_module(cmakelint)
find_python_module(github)
find_python_module(json2html)
find_python_module(lxml)
find_python_module(mypy)
find_python_module(openpyxl)
find_python_module(pandas)
find_python_module(pcre2)
find_python_module(pytest)
find_python_module(pytest_cov)
cmake_dependent_option(ENABLE_PYTHON_COVERAGE "Enable Python tests with coverage support" ON "PY_PYTEST_COV" OFF)

# sphinx documentation requirements
find_python_module(myst_parser)
find_python_module(sphinx)
find_python_module(sphinxcontrib.autojinja)
find_python_module(sphinx_rtd_theme)

if(PY_SPHINX AND PY_SPHINXCONTRIB.AUTOJINJA AND PY_SPHINX_RTD_THEME AND PY_MYST_PARSER)
    message(STATUS "Enabling docs directory as system supports Sphinx builds.")
    add_subdirectory("docs")
endif()

# prometheus_metrics requirements
find_python_module(prometheus_client)

# compliance-trestle requirements
find_python_module(requests)
find_python_module(trestle)

if(NOT SSG_TARGET_OVAL_VERSION VERSION_EQUAL "5.11")
    message(WARNING "You are targeting OVAL version ${SSG_TARGET_OVAL_VERSION}. In SSG we support/test 5.11 only!")
endif()

# OCP4 requires non-standard extensions. Vanilla OpenSCAP 1.2 doesn't support it.
# See also: https://github.com/ComplianceAsCode/content/issues/6798
if("${OSCAP_VERSION}" VERSION_LESS "1.3.4" AND SSG_PRODUCT_OCP4)
    set(SSG_PRODUCT_OCP4 OFF)
    message(WARNING "Won't build OCP4 content as it requires an OpenSCAP version with OCP4 support. See also: https://github.com/ComplianceAsCode/content/issues/6798. n.b.: if 1.3.4 fails to build OCP4 content, please update to 1.3.5")
endif()

# EKS requires non-standard extensions. Vanilla OpenSCAP 1.2 doesn't support it.

if("${OSCAP_VERSION}" VERSION_LESS "1.3.4" AND SSG_PRODUCT_EKS)
    set(SSG_PRODUCT_EKS OFF)
    message(WARNING "Won't build EKS content as it requires an OpenSCAP version with EKS support. See also: https://github.com/ComplianceAsCode/content/issues/6798. n.b.: if 1.3.4 fails to build EKS content, please update to 1.3.5")
endif()

set(LOG_LEVEL "WARNING")
if(SSG_LOG)
    set(LOG_LEVEL "DEBUG")
endif()

if(NOT SSG_THIN_DS)
    set(SSG_THIN_DS_RULE_ID "off")
endif()

if(SSG_JINJA2_CACHE_ENABLED)
    file(MAKE_DIRECTORY "${SSG_JINJA2_CACHE_DIR}")
    if(NOT EXISTS "${SSG_JINJA2_CACHE_DIR}")
        message(FATAL_ERROR "jinja2 cache dir was set to '${SSG_JINJA2_CACHE_DIR}'. This directory doesn't seem to exist and attempt to create it has failed.")
    endif()
    set(SSG_JINJA2_CACHE_ENABLED_BOOL "true")
else()
    set(SSG_JINJA2_CACHE_ENABLED_BOOL "false")
endif()

configure_file("${CMAKE_SOURCE_DIR}/build_config.yml.in" "${CMAKE_BINARY_DIR}/build_config.yml" @ONLY)

message(STATUS " ")
message(STATUS "Summary of Python Tools and Modules:")
# Required Python Tools
message(STATUS "python: ${Python_EXECUTABLE} (version: ${Python_VERSION})")
message(STATUS "python yaml module: ${PY_YAML}")
message(STATUS "python jinja2 module: ${PY_JINJA2}")
# Optional Python Tools
message(STATUS "python compliance-trestle module (optional): ${PY_TRESTLE}")
message(STATUS "python cmakelint module (optional): ${PY_CMAKELINT}")
message(STATUS "python github (PyGitHub) module (optional): ${PY_GITHUB}")
message(STATUS "python json2html module (optional): ${PY_JSON2HTML}")
message(STATUS "python lxml module (optional): ${PY_LXML}")
message(STATUS "python mypy module (optional): ${PY_MYPY}")
message(STATUS "python myst-parser module (optional): ${PY_MYST_PARSER}")
message(STATUS "python openpyxl module (optional): ${PY_OPENPYXL}")
message(STATUS "python pandas module (optional): ${PY_PANDAS}")
message(STATUS "python pcre2 module (optional): ${PY_PCRE2}")
message(STATUS "python prometheus-client module (optional): ${PY_PROMETHEUS_CLIENT}")
message(STATUS "python pytest_cov module (optional): ${PY_PYTEST_COV}")
message(STATUS "python pytest module (optional): ${PY_PYTEST}")
message(STATUS "python requests module (optional): ${PY_REQUESTS}")
message(STATUS "python sphinx module (optional): ${PY_SPHINX}")
message(STATUS "python sphinxcontrib.autojinja module (optional): ${PY_SPHINXCONTRIB.AUTOJINJA}")
message(STATUS "python sphinx_rtd_theme module (optional): ${PY_SPHINX_RTD_THEME}")
message(STATUS " ")
message(STATUS "Summary of System Tools:")
# Required System Tools
message(STATUS "oscap: ${OPENSCAP_OSCAP_EXECUTABLE} (version: ${OSCAP_VERSION})")
message(STATUS "sed: ${SED_EXECUTABLE}")
message(STATUS "xsltproc: ${XSLTPROC_EXECUTABLE}")
message(STATUS "xmllint: ${XMLLINT_EXECUTABLE}")
# Optional System Tools
message(STATUS "ansible-lint module (optional): ${ANSIBLE_LINT_EXECUTABLE}")
message(STATUS "ansible-playbook module (optional): ${ANSIBLE_PLAYBOOK_EXECUTABLE}")
message(STATUS "BATS framework (optional): ${BATS_EXECUTABLE}")
message(STATUS "grep (optional): ${GREP_EXECUTABLE}")
message(STATUS "linkchecker (optional): ${LINKCHECKER_EXECUTABLE}")
message(STATUS "shellcheck (optional): ${SHELLCHECK_EXECUTABLE}")
message(STATUS "yamllint module (optional): ${YAMLLINT_EXECUTABLE}")

message(STATUS " ")
message(STATUS "CMake Settings:")
message(STATUS "build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "build directory: ${CMAKE_BINARY_DIR}")
message(STATUS "generator: ${CMAKE_GENERATOR}")
message(STATUS "source directory: ${CMAKE_SOURCE_DIR}")

message(STATUS " ")
message(STATUS "Build options:")
message(STATUS "SSG vendor string: ${SSG_VENDOR}")
message(STATUS "Target OVAL version: ${SSG_TARGET_OVAL_VERSION}")
message(STATUS "Logging: ${SSG_LOG}")
message(STATUS "Ansible Playbooks: ${SSG_ANSIBLE_PLAYBOOKS_ENABLED}")
message(STATUS "Ansible Playbooks Per Rule: ${SSG_ANSIBLE_PLAYBOOKS_PER_RULE_ENABLED}")
message(STATUS "Bash scripts: ${SSG_BASH_SCRIPTS_ENABLED}")
message(STATUS "Build SCE Content: ${SSG_SCE_ENABLED}")
message(STATUS "Build SRG XLSX Export: ${SSG_SRG_XLSX_EXPORT}")
if(SSG_JINJA2_CACHE_ENABLED)
    message(STATUS "jinja2 cache: enabled")
    message(STATUS "jinja2 cache dir: ${SSG_JINJA2_CACHE_DIR}")
else()
    message(STATUS "jinja2 cache: disabled")
endif()
message(STATUS "Separate SCAP files: ${SSG_SEPARATE_SCAP_FILES_ENABLED}")
message(STATUS "STIG Delta Tailoring files: ${SSG_BUILD_DISA_DELTA_FILES}")
message(STATUS "Thin data streams: ${SSG_THIN_DS}")
message(STATUS "Pre-build Automatus tests: ${SSG_BUILT_TESTS_ENABLED}")

message(STATUS " ")
message(STATUS "Validation options:")
message(STATUS "BATS tests: ${SSG_BATS_TESTS_ENABLED}")
message(STATUS "Link Checker validation: ${SSG_LINKCHECKER_VALIDATION_ENABLED}")
message(STATUS "OVAL schematron validation: ${SSG_OVAL_SCHEMATRON_VALIDATION_ENABLED}")
message(STATUS "shellcheck bash fixes validation: ${SSG_SHELLCHECK_BASH_FIXES_VALIDATION_ENABLED}")
message(STATUS "SCAPVal 1.3 Enabled: ${ENABLE_SCAPVAL13}")
if(ENABLE_SCAPVAL13)
    message(STATUS "SCAPVAL Path: ${SCAPVAL_PATH}")
    if(NOT SCAPVAL_PATH)
        message(SEND_ERROR "Path to SCAPVal was not specified.")
    endif()
    find_program(JAVA_EXECUTABLE NAMES java)
    message(STATUS "java: ${JAVA_EXECUTABLE}")
    if(NOT JAVA_EXECUTABLE)
        message(SEND_ERROR "java is required for SCAPVal!")
    endif()
endif()
message(STATUS "Validate SCAP content: ${SSG_SCAP_VALIDATION_ENABLED}")
message(STATUS "Force validate everything: ${FORCE_VALIDATE_EVERYTHING}")
message(STATUS "Check if rules have been removed from the data stream ${ENABLE_CHECK_RULE_REMOVAL}")
if(ENABLE_CHECK_RULE_REMOVAL)
    message(STATUS "Old Release directory: ${OLD_RELEASE_DIR}")
    if(NOT OLD_RELEASE_DIR)
        message(SEND_ERROR "Path to the old release was not given. The CMake option OLD_RELEASE_DIR must be set.")
    endif()
endif()

message(STATUS " ")
message(STATUS "Products:")
message(STATUS "Amazon Linux 2023: ${SSG_PRODUCT_AL2023}")
message(STATUS "Alibaba Cloud Linux 2: ${SSG_PRODUCT_ALINUX2}")
message(STATUS "Alibaba Cloud Linux 3: ${SSG_PRODUCT_ALINUX3}")
message(STATUS "AlmaLinux OS 9: ${SSG_PRODUCT_ALMALINUX9}")
message(STATUS "Anolis OS 8: ${SSG_PRODUCT_ANOLIS8}")
message(STATUS "Anolis OS 23: ${SSG_PRODUCT_ANOLIS23}")
message(STATUS "Chromium: ${SSG_PRODUCT_CHROMIUM}")
message(STATUS "Debian 11: ${SSG_PRODUCT_DEBIAN11}")
message(STATUS "Debian 12: ${SSG_PRODUCT_DEBIAN12}")
message(STATUS "Debian 13: ${SSG_PRODUCT_DEBIAN13}")
message(STATUS "Example: ${SSG_PRODUCT_EXAMPLE}")
message(STATUS "EKS: ${SSG_PRODUCT_EKS}")
message(STATUS "Fedora: ${SSG_PRODUCT_FEDORA}")
message(STATUS "Firefox: ${SSG_PRODUCT_FIREFOX}")
message(STATUS "Kylin Server V10: ${SSG_PRODUCT_KYLINSERVER10}")
message(STATUS "OCP4: ${SSG_PRODUCT_OCP4}")
message(STATUS "RHCOS4: ${SSG_PRODUCT_RHCOS4}")
message(STATUS "Oracle Linux 7: ${SSG_PRODUCT_OL7}")
message(STATUS "Oracle Linux 8: ${SSG_PRODUCT_OL8}")
message(STATUS "Oracle Linux 9: ${SSG_PRODUCT_OL9}")
message(STATUS "Oracle Linux 10: ${SSG_PRODUCT_OL10}")
message(STATUS "OpenEmbedded: ${SSG_PRODUCT_OPENEMBEDDED}")
message(STATUS "openEuler 22.03 LTS: ${SSG_PRODUCT_OPENEULER2203}")
message(STATUS "openSUSE: ${SSG_PRODUCT_OPENSUSE}")
message(STATUS "RHEL 8: ${SSG_PRODUCT_RHEL8}")
message(STATUS "RHEL 9: ${SSG_PRODUCT_RHEL9}")
message(STATUS "RHEL 10: ${SSG_PRODUCT_RHEL10}")
message(STATUS "RHV 4: ${SSG_PRODUCT_RHV4}")
message(STATUS "SUSE 12: ${SSG_PRODUCT_SLE12}")
message(STATUS "SUSE 15: ${SSG_PRODUCT_SLE15}")
message(STATUS "SLE Micro 5: ${SSG_PRODUCT_SLMICRO5}")
message(STATUS "SLE Micro 6: ${SSG_PRODUCT_SLMICRO6}")
message(STATUS "TencentOS Server 4: ${SSG_PRODUCT_TENCENTOS4}")
message(STATUS "Ubuntu 22.04: ${SSG_PRODUCT_UBUNTU2204}")
message(STATUS "Ubuntu 24.04: ${SSG_PRODUCT_UBUNTU2404}")
message(STATUS " ")

# Remove this option when we would like to run ansible-lint and yamllint against our playbooks by
# default. Right now these checks are not performed and need to be enabled by adding
# -DANSIBLE_CHECKS=ON to cmake before running ctest.
option(ANSIBLE_CHECKS "Set to ON to enable ansible-lint and yamllint checks" OFF)
enable_testing()

add_subdirectory("tests")

# Targets 'stats', 'profile-stats' and 'zipfile' need to be added before any product because they
# will receive dependencies from products added.
ssg_build_zipfile_target("scap-security-guide-${SSG_VERSION}")

add_custom_target(stats)
add_custom_target(profile-stats)

add_custom_target(html-stats)
add_custom_target(html-profile-stats)

add_custom_target(render-policies)

ssg_build_man_page()

if(SSG_PRODUCT_AL2023)
    add_subdirectory("products/al2023" "al2023")
endif()
if(SSG_PRODUCT_ALINUX2)
    add_subdirectory("products/alinux2" "alinux2")
endif()
if(SSG_PRODUCT_ALINUX3)
    add_subdirectory("products/alinux3" "alinux3")
endif()
if(SSG_PRODUCT_ALMALINUX9)
    add_subdirectory("products/almalinux9" "almalinux9")
endif()
if(SSG_PRODUCT_ANOLIS8)
    add_subdirectory("products/anolis8" "anolis8")
endif()
if(SSG_PRODUCT_ANOLIS23)
    add_subdirectory("products/anolis23" "anolis23")
endif()
if(SSG_PRODUCT_CHROMIUM)
    add_subdirectory("products/chromium" "chromium")
endif()

if(SSG_PRODUCT_DEBIAN11)
    add_subdirectory("products/debian11" "debian11")
endif()
if(SSG_PRODUCT_DEBIAN12)
    add_subdirectory("products/debian12" "debian12")
endif()
if(SSG_PRODUCT_DEBIAN13)
    add_subdirectory("products/debian13" "debian13")
endif()
if(SSG_PRODUCT_EXAMPLE)
    add_subdirectory("products/example" "example")
endif()
if(SSG_PRODUCT_EKS)
    add_subdirectory("products/eks" "eks")
endif()
if(SSG_PRODUCT_FEDORA)
    add_subdirectory("products/fedora" "fedora")
endif()
if(SSG_PRODUCT_FIREFOX)
    add_subdirectory("products/firefox" "firefox")
endif()
if(SSG_PRODUCT_KYLINSERVER10)
    add_subdirectory("products/kylinserver10" "kylinserver10")
endif()
if(SSG_PRODUCT_OCP4)
    add_subdirectory("products/ocp4" "ocp4")
endif()
if(SSG_PRODUCT_RHCOS4)
    add_subdirectory("products/rhcos4" "rhcos4")
endif()
if(SSG_PRODUCT_OL7)
    add_subdirectory("products/ol7" "ol7")
endif()
if(SSG_PRODUCT_OL8)
    add_subdirectory("products/ol8" "ol8")
endif()
if(SSG_PRODUCT_OL9)
    add_subdirectory("products/ol9" "ol9")
endif()
if(SSG_PRODUCT_OL10)
    add_subdirectory("products/ol10" "ol10")
endif()
if(SSG_PRODUCT_OPENEMBEDDED)
    add_subdirectory("products/openembedded" "openembedded")
endif()
if(SSG_PRODUCT_OPENEULER2203)
    add_subdirectory("products/openeuler2203" "openeuler2203")
endif()
if(SSG_PRODUCT_OPENSUSE)
    add_subdirectory("products/opensuse" "opensuse")
endif()
if(SSG_PRODUCT_RHEL8)
    add_subdirectory("products/rhel8" "rhel8")
endif()
if(SSG_PRODUCT_RHEL9)
    add_subdirectory("products/rhel9" "rhel9")
endif()
if(SSG_PRODUCT_RHEL10)
    add_subdirectory("products/rhel10" "rhel10")
endif()
if(SSG_PRODUCT_RHV4)
    add_subdirectory("products/rhv4" "rhv4")
endif()
if(SSG_PRODUCT_SLE12)
    add_subdirectory("products/sle12" "sle12")
endif()
if(SSG_PRODUCT_SLE15)
    add_subdirectory("products/sle15" "sle15")
endif()
if(SSG_PRODUCT_SLMICRO5)
    add_subdirectory("products/slmicro5" "slmicro5")
endif()
if(SSG_PRODUCT_SLMICRO6)
    add_subdirectory("products/slmicro6" "slmicro6")
endif()
if(SSG_PRODUCT_TENCENTOS4)
    add_subdirectory("products/tencentos4" "tencentos4")
endif()
if(SSG_PRODUCT_UBUNTU2204)
    add_subdirectory("products/ubuntu2204" "ubuntu2204")
endif()
if(SSG_PRODUCT_UBUNTU2404)
    add_subdirectory("products/ubuntu2404" "ubuntu2404")
endif()

# ZIP only contains source datastreams and kickstarts.
# People who want sources to build from should get the tarball instead.
ssg_build_zipfile("scap-security-guide-${SSG_VERSION}")

ssg_define_guide_and_table_tests()

install(FILES "${CMAKE_SOURCE_DIR}/LICENSE"
    DESTINATION ${CMAKE_INSTALL_DOCDIR})
install(FILES "${CMAKE_SOURCE_DIR}/README.md"
    DESTINATION ${CMAKE_INSTALL_DOCDIR})
install(FILES "${CMAKE_SOURCE_DIR}/Contributors.md"
    DESTINATION ${CMAKE_INSTALL_DOCDIR})

install(FILES "${CMAKE_BINARY_DIR}/scap-security-guide.8"
    DESTINATION "${CMAKE_INSTALL_MANDIR}/man8")

# We use CPack to generate the tarball with all sources and packages for testing.
# Only CPack should follow.
set(CPACK_CMAKE_GENERATOR "Unix Makefiles")
set(CPACK_SOURCE_GENERATOR "TBZ2")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "scap-security-guide-${SSG_VERSION}" CACHE INTERNAL "tarball basename")
set(CPACK_SOURCE_IGNORE_FILES
"\\\\.git.*"
"\\\\.pyc"
"__pycache__"

"build/"
"~$"

"\\\\CMakeLists.txt.user"
)
# Common definitions for RPM and DEB packages
set(CPACK_PACKAGE_VERSION ${SSG_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Security guidance and baselines in SCAP formats")
set(CPACK_PACKAGE_VENDOR "scap-security-guide")
# The package contact is needed to build the deb package
set(CPACK_PACKAGE_CONTACT "open-scap-list@redhat.com")
set(CPACK_PACKAGE_RELOCATABLE FALSE)

# This adds "${?dist} to Release field in spec file
set(CPACK_RPM_PACKAGE_RELEASE "1%{?dist}")
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION "/usr/share/xml;/usr/share/man;/usr/share/man/man8")
set(CPACK_RPM_PACKAGE_GROUP "Applications/System")
set(CPACK_RPM_PACKAGE_LICENSE "BSD-3-Clause")
set(CPACK_RPM_PACKAGE_URL "https://www.open-scap.org/security-policies/scap-security-guide/")
set(CPACK_RPM_PACKAGE_ARCHITECTURE "noarch")
set(CPACK_RPM_PACKAGE_REQUIRES "xml-common, openscap-utils >= 1.0.8")
set(CPACK_RPM_PACKAGE_PROVIDES "openscap-content")
set(CPACK_RPM_PACKAGE_DESCRIPTION "The %{name} project provides a guide for configuration of the
system from the final system's security point of view. The guidance is
specified in the Security Content Automation Protocol (SCAP) format and
constitutes a catalog of practical hardening advice, linked to government
requirements where applicable. The project bridges the gap between generalized
policy requirements and specific implementation guidelines. The system
administrator can use the oscap command-line tool from the openscap-utils
package to verify that the system conforms to provided guidelines.
The %{name} package also contains HTML formatted documents containing
hardening guidances that have been generated from XCCDF benchmarks.
")

# Change the default file name of the RPMs.
# %{release} includes release number and dist type.
# This only has effect with cmake v3.6 or higher.
set(CPACK_RPM_FILE_NAME "%{name}-%{version}-%{release}.rpm")
# For older versions of cmake (e.g. v2.8) file name is defined like below.
set(CPACK_PACKAGE_FILE_NAME "scap-security-guide-${SSG_VERSION}")
set(CPACK_PACKAGE_CHECKSUM SHA512)
set(CPACK_GENERATOR "RPM;DEB")
include(CPack)
