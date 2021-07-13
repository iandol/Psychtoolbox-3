function result=EyelinkDoTrackerSetup(el, sendkey)
% USAGE: result=EyelinkDoTrackerSetup(el [, sendkey])
%
% el: Eyelink default values
%
% sendkey:  set to go directly into a particular mode
%           sendkey is optional and ignored if el.callback is defined for
%           callback based tracker setup.
%
%           'v', start validation
%           'c', start calibration
%           'd', start driftcorrection
%           13, or el.ENTER_KEY, show 'eye' setup image
%
% Note that EyelinkDoTrackerSetup() internally uses Beeper() and Snd() to play
% auditory feedback tones if el.targetbeep=1 or el.feedbackbeep=1 and the
% el.callback function is set to the default PsychEyelinkDispatchCallback().
% If you want to use PsychPortAudio in a script that also calls EyelinkDoTrackerSetup,
% then read "help Snd" for instructions on how to provide proper interoperation
% between PsychPortAudio and the feedback sounds created by Eyelink.

%
% 02-06-01  fwc removed use of global el, as suggest by John Palmer.
%               el is now passed as a variable, we also initialize Tracker state bit
%               and Eyelink key values in 'initeyelinkdefaults.m'
% 15-10-02  fwc added sendkey variable that allows to go directly into a particular mode
% 22-06-06  fwc OSX-ed
% 15-06-10  fwc added code for new callback version

global eyelinkanimationtarget;

doInit_eyelinkanimationtargetMovie = false;
if isempty(who('global', 'eyelinkanimationtargetMovie')) % if eyelinkanimationtargetMovie not yet initialized
    doInit_eyelinkanimationtargetMovie = true; % flag set after bringing global to workspace
end
global eyelinkanimationtargetMovie;
if doInit_eyelinkanimationtargetMovie
    eyelinkanimationtargetMovie = 0; % init movie pointer to 0
end

doInit_inDoTrackerSetup = false;
if isempty(who('global', 'inDoTrackerSetup')) % if inDoTrackerSetup not yet initialized
    doInit_inDoTrackerSetup = true; % flag set after bringing global to workspace
end
global inDoTrackerSetup; % checked by EyelinkDoDriftCorrection, if true then skips Screen('CloseMovie') before return here
if doInit_inDoTrackerSetup
    inDoTrackerSetup = true; % flag in EyelinkDoTrackerSetup
end

doInit_inDoDriftCorrection = false;
if isempty(who('global', 'inDoDriftCorrection')) % if inDoDriftCorrection not yet initialized
    doInit_inDoDriftCorrection = true;
end
global inDoDriftCorrection; % checked by EyelinkDoTrackerSetup, if true then skips Screen('CloseMovie') before return to EyelinkDoDriftCorrection
if doInit_inDoDriftCorrection
    inDoDriftCorrection = false; % not set in EyelinkDoDriftCorrection, init false
end

if nargin < 1
    error( 'USAGE: result=EyelinkDoTrackerSetup(el [,sendkey])' );
end
% if we have a callback set, we call it.
if ~isempty(el.callback)
    if eyelinkanimationtargetMovie == 0 && strcmpi(el.calTargetType, 'video') && ~isempty(el.calAnimationTargetFilename)
        loadanimationmovie(el);
    end
    result = Eyelink( 'StartSetup', 1 );
    if ~inDoDriftCorrection && eyelinkanimationtargetMovie ~= 0 && strcmpi(el.calTargetType, 'video')
        cleanupmovie(el);
    end
    return;
end

% else we continue with the old version
if nargin < 2
    sendkey = [];
end
result=EyelinkLegacyDoTrackerSetup(el, sendkey);
inDoTrackerSetup = false;
if ~inDoDriftCorrection
    clear global inDoTrackerSetup inDoDriftCorrection eyelinkanimationtarget eyelinkanimationtargetMovie; % cleanup globals
end
return


    function cleanupmovie(el)
        tex=Screen('GetMovieImage', eyewin, eyelinkanimationtarget.movie, 0);
        Screen('PlayMovie', eyelinkanimationtarget.movie, 0, el.calAnimationLoopParam);
%         if tex>0
            Screen('Close', tex);
%         end
        Screen('CloseMovie', eyelinkanimationtarget.movie);
        eyelinkanimationtarget.movie = 0;
    end


    function loadanimationmovie(el)
        [movie movieduration fps imgw imgh] = Screen('OpenMovie',  el.window, el.calAnimationTargetFilename, 0, 1, el.calAnimationOpenSpecialFlags1);
        eyelinkanimationtarget.movie = movie;
        eyelinkanimationtarget.movieduration = movieduration;
        eyelinkanimationtarget.fps = fps;
        eyelinkanimationtarget.imgw = imgw;
        eyelinkanimationtarget.imgh = imgh;
        % eyelinkanimationtarget.count = 1;
        eyelinkanimationtarget.calxy =[];
        Screen('SetMovieTimeIndex', eyelinkanimationtarget.movie, 0, el.calAnimationSetIndexIsFrames);
    end
end

