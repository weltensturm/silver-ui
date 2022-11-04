local path, namespace = ...

local TempLQT = namespace.LQT

if LQT and LQT.lqt_version ~= TempLQT.lqt_version then
    print('|cffff9900Warning|cffffffff: incompatible LQT versions')
    print('this:|cffffff00', TempLQT.lqt_version, '|cffffffff from ' .. path)
    print('other:|cffffff00', LQT.lqt_version, '|cffffffff from ' .. LQT.lqt_path)
end

LQT = TempLQT
