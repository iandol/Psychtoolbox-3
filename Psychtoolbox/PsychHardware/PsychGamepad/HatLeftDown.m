function result = HatLeftDown
% result = HatLeftDown
% Return a constant for hat left and down position.  To read a hat position, use:
% Gamepad('GetHat', gamepadIndex, hatIndex).

% 8/17/01   awi wrote it
% 7/21/03   awi added switch and OS X condition.
% 10/6/05   awi Note here cosmetic changes by dgp between 7/21/03 and 10/6/05


if IsOSX 
	result = 6;
end
