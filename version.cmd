@rem Set default version in case git isn't available.
set description=v2.24.2-1-1
@rem Get canonical version from git tags, eg v2.24.1-1-g2c60e53.
for /f %%v in ('git describe --tags --long') do set description=%%v

@rem Strip leading v if present, eg 2.24.1-1-g2c60e53.
@rem �������� v �� ������ �����
set description=%description:v=%
set version=%description%

@rem Get the number of commits and commit hash, eg 1-g2c60e53.
@rem �������� ���, ������� ������ - �� ������ �����, ������� n="1-g2c60e53"
set n=%version:*-=%
@rem �������� ���, ������� ������ - �� ������ �����, ������� commit=g2c60e53
set commit=%n:*-=%
@rem ������� � n ��, ��� � ���������� commit �� ������ �����, ������� n="1-"
call set n=%%n:%commit%=%%
@rem ������ � �������� ������� �� ������� � ����� (�� ������� ���), ������� n=1
set n=%n:~0,-1%

@rem Strip n and commit, eg 2.24. ������� 1-g2c60e53
call set version=%%version:%n%-%commit%=%%
@rem ������� ��������� -
set version=%version:~0,-1%

@rem Find major and minor.
@rem ������� �� ������ ������ ��� �� ������ ����� ������������, ������� minor, ���������� path
set minor=%version:*.=%
@rem ������� �� ������ ������ �������� �������� � ������ �����, ������� major
call set major=%%version:.%minor%=%%
@rem ������� �� minor �� ������ ����� ������������, ������� path
set path=%minor:*.=%
@rem �� ������� minor ������� path, ������� ������ minor
call set minor=%%minor:.%path%=%%

@rem Build flags.
set flags=0L

@rem Don't include n and commit if we match a tag exactly.
if "%n%" == "0" (set description=%major%.%minor%.%path%) else set flags=VS_FF_PRERELEASE
@rem Maybe we couldn't get the git tag.
if "%commit%" == "prerelease" set flags=VS_FF_PRERELEASE

@rem Ignore the build number if this isn't Jenkins.
if "%BUILD_NUMBER%" == "" set BUILD_NUMBER=0

@rem Copyright year provided by Jenkins.
set md=%BUILD_ID:*-=%
call set year=%%BUILD_ID:%md%=%%
set year=%year:~0,-1%
if "%BUILD_ID%" == "" set year=

@rem Create version.h.
@echo>version.h.new #define NSSM_VERSION _T("%description%")
@echo>>version.h.new #define NSSM_VERSIONINFO %major%,%minor%,%path%,%n%
@echo>>version.h.new #define NSSM_DATE _T("%DATE%")
@echo>>version.h.new #define NSSM_FILEFLAGS %flags%
@echo>>version.h.new #define NSSM_COPYRIGHT _T("Public Domain; Authors Iain Patterson 2003-2015, Gsb 2024")

fc version.h version.h.new >NUL: 2>NUL:
if %ERRORLEVEL% == 0 (del version.h.new) else (move /y version.h.new version.h)
