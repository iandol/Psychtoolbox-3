function VideoRecordingDemo(moviename, codec, withsound, showit, windowed, deviceId)
% VideoRecordingDemo(moviename [, codec=0][, withsound=0][, showit=1][, windowed=1][, deviceId=0])
%
% Demonstrates simple video capture and recording to a movie file.
%
% Supports GStreamer on all systems, and DC1394 engine on Linux and OSX.
%
% Please look at the source code of the demo carefully! Both macOS and
% MS-Windows often need special treatment in terms of codec and parameter
% selection to work reliably (or to be honest: To work at all).
%
% The demo starts the videocapture engine, recording video from the default
% video source and (optionally) sound from the default audio source. It
% encodes the video+audio data with the selected 'codec' and writes it to the
% 'moviename' movie file. Optionally it previews the recorded
% video onscreen (often at a much lower framerate to keep system load low
% enough for reliable recording). Recording ends if any key is pressed on
% the keyboard.
%
% Arguments and their meaning:
%
% 'moviename' name of output movie file. The file must not exist at start
% of recording, otherwise it is overwritten.
%
% 'codec' Indicate the type of video codec you want to use.
% Defaults to "whatever the system default is". Some codecs are very fast,
% i.e., high framerates and low system load, others provide high compression
% rates, i.e., small video files at good quality. Usually there's a tradeoff
% between encoding speed, quality and compression ratio, so you'll have to try
% out different ones to find one suitable for your purpose. Some codecs only
% work at specific framerates or for specific image sizes.
%
% The supported codecs and settings with GStreamer can be found in the code
% and are explained in 'help VideoRecording'.
%
% Empirically, the MPEG-4 or H264 codecs seem to provide a good tradeoff
% between quality, compression, speed and cpu load. They allow to reliably
% record drop-free sound and video with a resolution of 640x480 pixels at
% 30 frames per second.
%
% H.264 has better quality and higher compression, but is able to nearly
% saturate a MacBookPro, so reliable recording at 30 fps may be difficult
% to achieve or needs more powerful machines.
%
% Some of the other codecs may provide the highest image quality and lowest
% cpu load, but they also produce huge files, e.g., all the DVxxx codecs
% for PAL and NTSC video capture, as well as the component video codecs.
%
% 'withsound' If set to non-zero, sound will be recorded as well.
%
% 'showit' If non-zero, video will be shown onscreen during recording
% (default: Show it). Not showing the video during recording will
% significantly reduce system load, so this may help to sustain a skip free
% recording on lower end machines.
%
% 'windowed' If set to non-zero, show captured video in a window located at
% the top-left corner of the screen, instead of fullscreen. Windowed
% display is the default.
%
% 'deviceId' Optional deviceIndex of the video capture device. Defaults to
% 0 for the default video capture device.
%
% Tip on Linux: If you have an exotic camera which only delivers video in non-standard
% video formats, and Psychtoolbox does not handle this automatically, but aborts with
% some GStreamer errors, e.g., "source crop failed", or "negotiation error", you may
% be able to work around the problem (after a "clear all" or fresh start), by adding
% this command: setenv('GST_V4L2_USE_LIBV4L2','1');
% This will use of a helper library that can convert some video formats which
% GStreamer or Psychtoolbox can not handle automatically yet. In any case, please
% report your problem to the Psychtoolbox user forum, so proper automatic handling
% of your camera model can be added to a future Psychtoolbox version.
%
% Tip for the Microsoft Surface Pro 6 tablet and similar: The builtin cameras only
% work if you explicitely specify the 'pixeldepth' parameter in Screen('OpenVideoCapture')
% as value 6 for YUV-I420 encoding. This seems to be a quirk of the builtin cameras, as
% of Windows-10 (20H2) from December 2020.
%

% History:
% 11.2.2007   Written (MK).
%  5.6.2011   Updated for GStreamer support on Linux and Windows (MK).
%  3.9.2012   Updated to handle both legacy Quicktime and modern GStreamer (MK).
% 19.11.2013  Drop Quicktime support, add dc1394 support, update help text (MK).
% 29.12.2013  Make less broken on OSX and Windows (MK).
% 26.08.2014  Adapt to new GStreamer-1 based engine (MK).
% 02.12.2021  Change codec for macOS 10.15 to avenc_h263p, default H264 hangs (MK).
% 22.08.2024  Remove Windows special path. Cleanups (MK).
% 10.12.2024  Refinement for macOS Apple Silicon (MK).

% Test if we're running on PTB-3, abort otherwise:
AssertOpenGL;

% Only report ESCape key press via KbCheck:
KbName('UnifyKeyNames');
RestrictKeysForKbCheck(KbName('ESCAPE'));

% Open window on secondary display, if any:
screen=max(Screen('Screens'));

if nargin < 1
    error('You must provide a output movie name as first argument!');
end
fprintf('Recording to movie file %s ...\n', moviename);

if exist(moviename, 'file')
    delete(moviename);
    warning('Moviefile %s existed already! Will overwrite it...', moviename); %#ok<WNTAG>
end

% Assign default codec if none assigned:
if nargin < 2
    codec = [];
end

if nargin < 3 || isempty(withsound)
    withsound = 0;
end

if withsound > 0
    % A setting of '2' (ie 2nd bit set) means: Enable sound recording.
    withsound = 2;
else
    withsound = 0;
end

% If no user specified codec, then choose one of the following:
if isempty(codec)
    % These do not work yet:
    %codec = ':CodecType=huffyuv'  % Huffmann encoded YUV + MPEG-4 audio: FAIL!
    %codec = ':CodecType=avenc_h263p'  % H263 video + MPEG-4 audio: FAIL!
    %codec = ':CodecType=yuvraw' % Raw YUV + MPEG-4 audio: FAIL!
    %codec = ':CodecType=xvidenc Keyframe=60 Videobitrate=8192 'Missing!
    
    % These are so slow, they are basically useless for live recording:
    %codec = ':CodecType=theoraenc'% Theoravideo + Ogg vorbis audio: Gut @ 320 x 240
    %codec = ':CodecType=vp8enc_webm'   % VP-8/WebM  + Ogg vorbis audio: Ok @ 320 x 240, miserabel higher.
    %codec = ':CodecType=vp8enc_matroska'   % VP-8/Matroska  + Ogg vorbis audio: Gut @ 320 x 240
    
    % The good ones...
    %codec = ':CodecType=avenc_mpeg4' % % MPEG-4 video + audio: Ok @ 640 x 480.
    %codec = ':CodecType=x264enc Keyframe=1 Videobitrate=8192 AudioCodec=alawenc ::: AudioSource=pulsesrc ::: Muxer=qtmux'  % H264 video + MPEG-4 audio: Tut seshr gut @ 640 x 480
    %codec = ':CodecType=VideoCodec=x264enc speed-preset=1 noise-reduction=100000 ::: AudioCodec=faac ::: Muxer=avimux'
    %codec = ':CodecSettings=Keyframe=60 Videobitrate=8192 '
    
    if IsLinux
        % Linux, where stuff "just works(tm)": Assign default auto-selected codec:
        codec = ':CodecType=DEFAULTencoder';
    end

    if IsOSX
        % Default codec works, but sound recording is broken at least on
        % GStreamer 1.24.10 on Apple Silicon, possibly on others as well.
        codec = ':CodecType=DEFAULTencoder';
    end

    if IsWin
        % Windows: H264 encoder often doesn't work out of the box without
        % overloading the machine. Choose theora encoder instead, which
        % seems to be more well-behaved and fast enough on modern machines.
        % Also, at least my test machine needs an explicitely defined audio
        % source, as the autoaudiosrc does not find any sound sources on
        % the Windows-7 PC :-(
        if withsound
            codec = ':CodecType=DEFAULTencoder ::: AudioSource=directsoundsrc';
        else
            codec = ':CodecType=DEFAULTencoder';
        end
    end
else
    % Assign specific user-selected codec:
    codec = [':CodecType=' codec];
end

fprintf('Using codec: %s\n', codec);

if nargin < 4 || isempty(showit)
    showit = 1;
end

if showit > 0
    % We perform blocking waits for new images:
    waitforimage = 1;
else
    % We only grant processing time to the capture engine, but don't expect
    % any data to be returned and don't wait for frames:
    waitforimage = 4;
    
    % Setting the 3rd bit of 'withsound' (= adding 4) disables some
    % internal processing which is not needed for pure disk recording. This
    % can safe significant amounts of processor load --> More reliable
    % recording on low-end hardware. Setting the 5th bit (bit 4) aka adding
    % +16 will offload the recording to a separate processing thread. Pure
    % recording is then fully automatic and makes better use of multi-core
    % processor machines.
    withsound = withsound + 4 + 16;
end

% Always request timestamps in movie recording time instead of GetSecs() time:
withsound = withsound + 64;

if nargin < 5
    windowed = [];
end

if isempty(windowed)
    windowed = 1;
end

if nargin < 6
    deviceId = [];
end

try
    if windowed > 0
        % Open window in top left corner of screen. We ask PTB to continue
        % even in case of video sync trouble, as this is sometimes the case
        % on OS/X in windowed mode - and we don't need accurate visual
        % onsets in this demo anyway:
        oldsynclevel = Screen('Preference', 'SkipSyncTests', 1);
        
        % Open 800x600 pixels window at top-left corner of 'screen'
        % with black background color:
        win=Screen('OpenWindow', screen, 0, [0 0 800 600]);
    else
        % Open fullscreen window on 'screen', with black background color:
        oldsynclevel = Screen('Preference', 'SkipSyncTests');
        win=Screen('OpenWindow', screen, 0);
    end
    
    % Initial flip to a blank screen:
    Screen('Flip',win);
    
    % Set text size for info text. 24 pixels is also good for Linux.
    Screen('TextSize', win, 24);
    
    % Capture and record video + audio to disk: 'deviceId' is capture device.
    % Specify the special flags in 'withsound', the codec settings for
    % recording in 'codec'. Leave everything else at auto-detected defaults:
    grabber = Screen('OpenVideoCapture', win, deviceId, [], [], [], [], codec, withsound);

    % Wait a bit between 'OpenVideoCapture' and start of capture below.
    % This gives the engine a bit time to spin up and helps avoid jerky
    % recording at the first iteration after startup of Octave/Matlab.
    % Successive recording iterations won't need this anymore:
    WaitSecs('YieldSecs', 2);
    
    for nreps = 1:1
        KbReleaseWait;
        
        % Select a moviename for the recorded movie file:
        mname = sprintf('SetNewMoviename=%s_%i.mov', moviename, nreps);
        Screen('SetVideoCaptureParameter', grabber, mname);
        
        % Start capture, request 30 fps. Capture hardware will fall back to
        % fastest supported framerate if it is not supported (i think).
        % Some hardware disregards the framerate parameter. Especially the
        % built-in iSight camera of the newer Intel Macintosh computers
        % seems to completely ignore any framerate setting. It chooses the
        % framerate by itself, based on lighting conditions. With bright scenes
        % it can run at 30 fps, at lower light conditions it reduces the
        % framerate to 15 fps, then to 7.5 fps.
        Screen('StartVideoCapture', grabber, realmax, 1)
        
        oldtex = 0;
        oldpts = 0;
        count = 0;
        t=GetSecs;
        
        % Run until keypress:
        while ~KbCheck
            % Wait blocking for next image. If waitforimage == 1 then return it
            % as texture, if waitforimage == 4, do not return it (no preview,
            % but faster). oldtex contains the handle of previously fetched
            % textures - recycling is not only good for the environment, but also for speed ;)
            if waitforimage~=4
                % Live preview: Wait blocking for new frame, return texture
                % handle and capture timestamp:
                [tex, pts, nrdropped]=Screen('GetCapturedImage', win, grabber, waitforimage, oldtex); %#ok<ASGLU>
                
                % Some output to the console:
                % fprintf('tex = %i  pts = %f nrdropped = %i\n', tex, pts, nrdropped);
                
                % If a texture is available, draw and show it.
                if tex > 0
                    % Print capture timestamp in seconds since start of capture:
                    Screen('DrawText', win, sprintf('Capture time (secs): %.4f', pts), 0, 0, 255);
                    if count>0
                        % Compute delta between consecutive frames:
                        delta = (pts - oldpts) * 1000;
                        oldpts = pts;
                        Screen('DrawText', win, sprintf('Interframe delta (msecs): %.4f', delta), 0, 20, 255);
                    end
                    
                    % Draw new texture from framegrabber.
                    Screen('DrawTexture', win, tex);
                    
                    % Recycle this texture - faster:
                    oldtex = tex;
                    
                    % Show it:
                    Screen('Flip', win);
                    count = count + 1;
                else
                    WaitSecs('YieldSecs', 0.005);
                end
            else
                % Recording only: We have nothing to do here, as thread offloading
                % is enabled above via flag 16 so all processing is done automatically
                % in the background.
                
                % Well, we do one thing. We sleep for 0.1 secs to avoid taxing the cpu
                % for no good reason:
                WaitSecs('YieldSecs', 0.1);
            end
            % Ready for next frame:
        end
        
        % Done. Shut us down.
        telapsed = GetSecs - t;
        
        % Stop capture engine and recording:
        Screen('StopVideoCapture', grabber);
    end
    
    % Close engine and recorded movie file:
    Screen('CloseVideoCapture', grabber);
    
    % Close display, release all remaining ressources:
    sca;
    
    avgfps = count / telapsed; %#ok<NASGU>
catch
    % In case of error, the 'CloseAll' call will perform proper shutdown
    % and cleanup:
    RestrictKeysForKbCheck([]);
    sca;
end

% Allow KbCheck et al. to query all keys:
RestrictKeysForKbCheck([]);

% Restore old vbl sync test mode:
Screen('Preference', 'SkipSyncTests', oldsynclevel);

fprintf('Done. Bye!\n');
