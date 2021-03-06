function [OS, OSVersion] = detectOS
%DETECTOS Name and version number of the operating system.
%   OS = DETECTOS returns the name of the operating system as one of the
%   following character vectors: 'windows', 'macos' (which includes OS X),
%   'solaris', 'aix', or another Unix/Linux distro in all lowercase
%   characters (such as 'ubuntu' or 'centos'). An error is thrown if the
%   operating system cannot be determined.
%
%   [~, OSVERSION] = DETECTOS returns the operating system version number
%   as a numeric row vector. For example, version 6.1.7601 is reported as
%   OSVERSION = [6, 1, 7601]. If the OS version cannot be determined, a
%   warning is issued and the empty numeric array is returned.
%
%See also COMPUTER, ISMAC, ISPC, ISUNIX.

% Created 2016-01-05 by Jorg C. Woehl
% 2016-10-10 (JCW): Converted to standalone function, comments added.

if ismac
    % Mac
    % see https://support.apple.com/en-us/HT201260 for version numbers
    OS = 'macos';
    [status, OSVersion] = system('sw_vers -productVersion');
    OSVersion = strtrim(OSVersion);
    if (~(status == 0) || isempty(OSVersion))
        warning('detectOS:UnknownMacOSVersion',...
            'Unable to determine macOS/OS X version.');
        OSVersion = '';
    end
elseif ispc
    % Windows
    % see https://en.wikipedia.org/wiki/Ver_(command) for version numbers
    OS = 'windows';
    [status, OSVersion] = system('ver');
    OSVersion = regexp(OSVersion, '\d[.\d]*', 'match');
    if (~(status == 0) || isempty(OSVersion))
        warning('detectOS:UnknownWindowsVersion',...
            'Unable to determine Windows version.');
        OSVersion = '';
    end
elseif isunix
    % Unix/Linux
    % inspired in part by
    %   http://linuxmafia.com/faq/Admin/release-files.html and
    %   http://unix.stackexchange.com/questions/92199/how-can-i-reliably-get-the-operating-systems-name/92218#92218
    [status, OS] = system('uname -s');          % results in 'SunOS', 'AIX', or 'Linux'
    OS = strtrim(OS);
    assert((status == 0), 'detectOS:UnknownUnixDistro',...
        'Unable to determine Unix distribution.');
    if strcmpi(OS, 'SunOS')
        OS = 'solaris';                      	% newer name
        [status, OSVersion] = system('uname -v'); % example:
        OSVersion = regexp(OSVersion, '\d[.\d]*', 'match');
        if (~(status == 0) || isempty(OSVersion))
            warning('detectOS:UnknownSolarisVersion',...
                'Unable to determine Solaris version.');
            OSVersion = '';
        end
    elseif strcmpi(OS, 'AIX')
        OS = 'aix';
        [status, OSVersion] = system('oslevel'); % example: 6.1.0.0
        OSVersion = regexp(OSVersion, '\d[.\d]*', 'match');
        if (~(status == 0) || isempty(OSVersion))
            warning('detectOS:UnknownAIXVersion',...
                'Unable to determine AIX version.');
            OSVersion = '';
        end
    elseif strcmpi(OS, 'Linux')
        OS = '';
        OSVersion = '';
        % first check if /etc/os-release exists and read it
        [status, result] = system('cat /etc/os-release');
        if (status == 0)
            % add newline to beginning and end of output character vector (makes parsing easier)
            result = sprintf('\n%s\n', result);
            % determine OS
            OS = regexpi(result, '(?<=\nID=).*?(?=\n)', 'match'); % ID=... (shortest match)
            OS = lower(strtrim(strrep(OS, '"', ''))); % remove quotes, leading/trailing spaces, and make lowercase
            if ~isempty(OS)
                % convert to character vector
                OS = OS{1};
            end
            % determine OS version
            OSVersion = regexpi(result, '(?<=\nVERSION_ID=)"*\d[.\d]*"*(?=\n)', 'match'); % VERSION_ID=... (longest match)
            OSVersion = strrep(OSVersion, '"', ''); % remove quotes
        else
            % check for output from lsb_release (more standardized than /etc/lsb-release itself)
            [status, result] = system('lsb_release -a');
            if (status == 0)
                % add newline to beginning and end of output character vector (makes parsing easier)
                result = sprintf('\n%s\n', result);
                % determine OS
                OS = regexpi(result, '(?<=\nDistributor ID:\t).*?(?=\n)', 'match'); % Distributor ID: ... (shortest match)
                OS = lower(strtrim(OS));      % remove leading/trailing spaces, and make lowercase
                if ~isempty(OS)
                    % convert to character vector
                    OS = OS{1};
                end
                % determine OS version
                OSVersion = regexpi(result, '(?<=\nRelease:\t)\d[.\d]*(?=\n)', 'match'); % Release: ... (longest match)
            else
                % extract information from /etc/*release or /etc/*version filename
                [status, result] = system('ls -m /etc/*version');   % comma-delimited file listing
                fileList = '';
                if (status == 0)
                    fileList = result;
                end
                [status, result] = system('ls -m /etc/*release');	% comma-delimited file listing
                if (status == 0)
                    fileList = [fileList ', ' result];
                end
                fileList = strrep(fileList, ',', ' ');
                % remove spaces and trailing newline
                fileList = strtrim(fileList);
                OSList = regexpi(fileList, '(?<=/etc/).*?(?=[-_][rv])', 'match'); % /etc/ ... -release/version or _release/version
                fileList = strtrim(strsplit(fileList));
                % find the first entry that's different from 'os', 'lsb', 'system', '', or 'debian'/'redhat' (unless it's the only one)
                ii = 1;
                while (ii <= numel(OSList))
                    if ~(strcmpi(OSList{ii}, 'os') || strcmpi(OSList{ii}, 'lsb') || strcmpi(OSList{ii}, 'system') || ...
                            isempty(OSList{ii}) || strcmpi(OSList{ii}, 'redhat') || strcmpi(OSList{ii}, 'debian'))
                        OS = OSList{ii};
                        OSFile = fileList{ii};
                        break;
                    elseif (strcmpi(OSList{ii}, 'redhat') || strcmpi(OSList{ii}, 'debian'))
                        OS = OSList{ii};          % assign temporarily, but keep going
                        OSFile = fileList{ii};
                    end
                    ii = ii+1;
                end
                % determine OS version
                if ~isempty(OSFile)
                    [status, OSVersion] = system(['cat ' OSFile]);
                    if (status == 0)
                        OSVersion = regexp(OSVersion, '\d[.\d]*', 'match');
                    else
                        OSVersion = '';
                    end
                end
            end
        end
        assert(~isempty(OS), 'detectOS:UnknownLinuxDistro',...
            'Unable to determine Linux distribution.');
        if isempty(OSVersion)
            warning('detectOS:UnknownLinuxVersion',...
                'Unable to determine Linux version.');
            OSVersion = '';
        end
    else
        error('detectOS:UnknownUnixDistro',...
            'Unknown Unix distribution.')
    end
else
    error('detectOS:PlatformNotSupported',...
        'Platform not supported.');
end

if iscell(OSVersion)
    % convert to character vector
    OSVersion = OSVersion{1};
end
OSVersion = round(str2double(strsplit(OSVersion, '.')));

end