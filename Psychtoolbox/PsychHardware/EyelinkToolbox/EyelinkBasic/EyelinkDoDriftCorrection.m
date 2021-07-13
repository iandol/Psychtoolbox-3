function success=EyelinkDoDriftCorrection(el, x, y, draw, allowsetup)
% success=EyelinkDoDriftCorrection(el [, x][, y][, draw][, allowsetup])
%
% DO PRE-TRIAL DRIFT CORRECTION
% We repeat if ESC key pressed to do setup.
% Setup might also have erased any pre-drawn graphics.
%
% Note that EyelinkDoDriftCorrection() internally uses Beeper() and Snd() to play
% auditory feedback tones if el.targetbeep=1 or el.feedbackbeep=1 and the
% el.callback function is set to the default PsychEyelinkDispatchCallback().
% If you want to use PsychPortAudio in a script that also calls EyelinkDoDriftCorrection,
% then read "help Snd" for instructions on how to provide proper interoperation
% between PsychPortAudio and the feedback sounds created by Eyelink.
%
global eyelinkanimationtarget;

doInit_eyelinkanimationtargetMovie = false;
if isempty(who('global', 'eyelinkanimationtargetMovie')) % if eyelinkanimationtargetMovie not yet initialized
    doInit_eyelinkanimationtargetMovie = true; % flag init after bringing global to workspace
end
global eyelinkanimationtargetMovie;
if doInit_eyelinkanimationtargetMovie
    eyelinkanimationtargetMovie = 0; % init movie pointer to 0
end

doInit_inDoTrackerSetup = false;
if isempty(who('global', 'inDoTrackerSetup')) % if inDoTrackerSetup not yet initialized
    doInit_inDoTrackerSetup = true;
end
global inDoTrackerSetup; % checked by EyelinkDoDriftCorrection, if true then skips Screen('CloseMovie') before return here
if doInit_inDoTrackerSetup
    inDoTrackerSetup = false; % not set in EyelinkDoTrackerSetup, init false
end

doInit_inDoDriftCorrection = false;
if isempty(who('global', 'inDoDriftCorrection')) % if inDoDriftCorrection not yet initialized
    doInit_inDoDriftCorrection = true;
end
global inDoDriftCorrection; % checked by EyelinkDoTrackerSetup, if true then skips Screen('CloseMovie') before return to EyelinkDoDriftCorrection
if doInit_inDoDriftCorrection
    inDoDriftCorrection = true; % flag in EyelinkDoDriftCorrection
end

success=1;

% if no x and y are supplied, set x,y to center coordinates
if ~exist('x', 'var') || isempty(x) || ~exist('y', 'var') || isempty(y)
    [x,y] = WindowCenter(el.window); % convenience routine part of eyelink toolbox
end

if ~exist('draw', 'var') || isempty(draw)
    draw=1;
end

if ~exist('allowsetup', 'var') || isempty(allowsetup)
    allowsetup=1;
end

while 1
    if Eyelink('IsConnected')==el.notconnected   % Check link often so we don't lock up if tracker lost
        success=0;
        return;
    end
    
    if ~isempty(el.callback) % if we have a callback set, we call it.
        if eyelinkanimationtargetMovie == 0 && strcmpi(el.calTargetType, 'video') && ~isempty(el.calAnimationTargetFilename)
            loadanimationmovie(el);
        end
        result = Eyelink('DriftCorrStart', x, y, 1, draw, allowsetup);
        
    else
        % else we continue with the old version
        result = EyelinkLegacyDoDriftCorrect(el, x, y, draw, allowsetup);
    end
    
    if result==el.TERMINATE_KEY
        success=0;
        return;
    end
    
    % repeat if ESC was pressed to access Setup menu
    if(result~=el.ESC_KEY)
        break;
    end
    
end % while
if ~doInit_inDoTrackerSetup && eyelinkanimationtargetMovie ~= 0 && strcmpi(el.calTargetType, 'video')
    cleanupmovie(el);
end
inDoDriftCorrection = false;
if ~inDoTrackerSetup
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
