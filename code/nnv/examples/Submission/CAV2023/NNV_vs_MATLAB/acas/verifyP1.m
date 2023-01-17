function verifyP1(reachOptionsList)

    % Setup the property
    resMAT = [];
    resNNV = [];
    timeMAT = zeros(45,1);
    n = length(reachOptionsList);
    timeNNV = zeros(45,n);
    timeNNVver = zeros(45,n);
    
    XLower = [0.6; -0.5; -0.5; 0.45; -0.5];
    XUpper = [0.679857769; 0.5; 0.5; 0.5; -0.45];
    
    % NNV
%     IS = Star(XLower, XUpper); % Input set
    IS = ImageStar(XLower, XUpper);
    H = [1 0 0 0 0];
    g = 3.991125645861615;
%     reachOpt = struct;
%     reachOpt.reachMethod = 'approx-star';
    
    % MATLAB
%     label = 1;
    XLower = dlarray(XLower, "CB");
    XUpper = dlarray(XUpper, "CB");
    
    % Iterate through all the networks to verify
    acasFolder = "/home/manzand/Documents/MATLAB/vnncomp2022_benchmarks/benchmarks/acasxu/onnx/";
%     acasFolder = "/home/dieman95/Documents/MATLAB/vnncomp2022_benchmarks/benchmarks/acasxu/onnx/";
    networks = dir(acasFolder);
    
    for i = 3:length(networks)
        % Load Network
        file = acasFolder + string(networks(i).name);
        net = importONNXNetwork(file, InputDataFormats='BCSS');

        % transform into NNV
        netNNV = matlab2nnv(net);

        % Transform the layers to fit MATLAB's algorithm
        Layers = net.Layers;
        Layers = Layers(5:end-1); % remove input and output layers
        input_layer = featureInputLayer(5); % number of inputs to acas xu
        elem_idxs = 2:3:length(Layers); % elementwiseLayers position
        for k=elem_idxs
            Layers(k-1).Bias = Layers(k).Offset; % add offset as bias on previous layer
        end
        Layers(elem_idxs) = []; % remove elementwiselayer
        netMAT = dlnetwork([input_layer; Layers]); % create dlnetwork for verification

        % Verify MATLAB
        t = tic;
%         res = verifyNetworkRobustness(netMAT, XLower, XUpper, label);
        [YLower, YUpper] = estimateNetworkOutputBounds(netMAT, XLower, XUpper);
        res = verifyMAT(YLower, YUpper);
        timeMAT(i-2) = toc(t);
        resMAT = [resMAT; res];
        
        % Verify NNV
        res = [];
        for r = 1:length(reachOptionsList)
            reachOpt = reachOptionsList(r);
            t = tic;
            R = netNNV.reach(IS, reachOpt);
            timeNNV(i-2,r) = toc(t);
            R = R.toStar;
            t = tic;
            res = [res, verifyNNV(R, H, g)];
            timeNNVver(i-2,r) = toc(t);
        end
        resNNV = [resNNV; res];
        
        
    end

    % Save results
    save("results_p1", "resMAT", "resNNV", "timeMAT", "timeNNV", "timeNNVver");

end

%% Helper Functions

function result = verifyMAT(YLower, YUpper)
    if YLower(1) >= 3.991125645861615
        result = categorical("verified");
    elseif YUpper(1) <= 3.991125645861615
        result = categorical("violated");
    else
        result = categorical("unproven");
    end
end

function result = verifyNNV(Set, H, b)
    S = Set.intersectHalfSpace(-H,-b);
    if isempty(S)
        result = categorical("verified");
    else
        result = categorical("unproven");
    end
end

% function result = verifyNNV(Set, H, b)
%     S = Set.intersectHalfSpace(H,b);
%     if isempty(S)
%         result = categorical("violated");
%     elseif Set.isSubSet(S) % Set <= S (reachable set is a contained in S (result of the intersection of Set and property))
%         result = categorical("verified");
%     else
%         result = categorical("unproven");
%     end
% end
