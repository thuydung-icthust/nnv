function t = reach()

%% Reachability analysis of the Unicycle (benchmark 10)
    
%%  Load components

    % Load controller
    net = load_NN_from_mat('controllerB_nnv.mat');
    controlPeriod = 0.2;
    reachstep = 0.05;
    plant = NonLinearODE(4,2,@dynamics10, reachstep, controlPeriod, eye(4));
    plant.set_taylorTerms(4);
    plant.set_zonotopeOrder(100);
    plant.set_tensorOrder(2);
%     plant.set_polytopeOrder(50);% error = 0.001;
    % error = 0.0005;
    % plant.options.maxError = [error; error; error; error];
%     tFinal = 10;
%     ****offset applied in dynamics
%     offset = 20;
%     offsetM = offset*ones(2,1);
%     scale_factor = 1;
    
%% Reachability analysis

    % Initial set
    lb = [9.5; -4.5; 2.1; 1.5];
    ub = [9.5001; -4.4999; 2.1001; 1.5001];
%     ub = [9.55; -4.45; 2.11; 1.51];
    init_set = Star(lb,ub);
    % Store all reachable sets
    reachAll = init_set;
    % Execute reachabilty analysis
%     steps = 10;
    steps = 30;
    reachOptions.reachMethod ='approx-star';
    t = tic;
    for i=1:steps
        % Compute controller output set
        input_set = net.reach(init_set,reachOptions);
        % Compute plant reachable set
        init_set = plantReach(plant,init_set,input_set,'lin');
        reachAll = [reachAll init_set];
    end
    t = toc(t);
    
    % path_out = [path_results(), filesep, 'Unicycle', filesep];
    % mkdir(path_out)
    % save([path_out, 'reach.mat'],'t','reachAll','-v7.3')

%% Visualize results
    plant.get_interval_sets;

    f = figure;
    hold on;
    Star.plotBoxes_2D_noFill(plant.intermediate_reachSet,1,2,'b');
    grid;
    xlabel('x1');
    ylabel('x2');
%     saveas(f,[path_out, 'reach1v2.pdf']);
    
    f1 = figure;
    hold on;
    Star.plotBoxes_2D_noFill(plant.intermediate_reachSet,3,4,'b');
    grid;
    xlabel('x1');
    ylabel('x2');
%     saveas(f1,[path_out, 'reach3v4.pdf']);

end

%% Helper function
function init_set = plantReach(plant,init_set,input_set,algoC)
    nS = length(init_set);
    nL = length(input_set);
    ss = [];
    for k=1:nS
        for l=1:nL
            ss =[ss plant.stepReachStar(init_set(k), input_set(l),algoC)];
        end
    end
    init_set = ss;
end