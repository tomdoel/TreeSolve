function TDL_OutputToCmgui(filename_prefix, vessel_tree)
    % TDL_OutputToCmgui Output a TreeSolve vessel tree to CMGUI format
    %
    %     Author: Tom Doel www.tomdoel.com
    %     Part of TreeSolve. http://github.com/tomdoel/TreeSolve
    %     Distributed under the GNU GPL v3 licence. Please see LICENSE file.
    %    


    vessel_tree = CalculateStartAndEndpoints(vessel_tree);
    vessel_tree = CalculateAllCoordinates(vessel_tree);


    node_lists = WriteNodeFile(filename_prefix, vessel_tree);
    WriteElemFile(filename_prefix, vessel_tree, node_lists);

    
function node_lists = WriteNodeFile(filename_prefix, vessel_tree)

    initial_text = {...
     ' Group name: vessel', ...
     ' #Fields=           4', ...
     ' 1) coordinates, coordinate, rectangular cartesian, #Components=3', ...
     '   x.  Value index= 1, #Derivatives=0', ...
     '   y.  Value index= 2, #Derivatives=0', ...
     '   z.  Value index= 3, #Derivatives=0', ...
     ' 2) pressure, field, rectangular cartesian, #Components=1', ...
     '   pressure.  Value index= 4, #Derivatives=0', ...
     ' 3) radius, field, rectangular cartesian, #Components=1', ...
     '   radius.  Value index= 5, #Derivatives=0', ...
     ' 4) velocity, field, rectangular cartesian, #Components=1', ...
     '   velocity.  Value index= 6, #Derivatives=0', ...
     };

 
    fid = fopen([filename_prefix '.exnode'],'w'); 

    for text = initial_text
       fprintf(fid, '%s\n', char(text)); 
    end

    node_number = 1;

    for vessel_index = 1 : length(vessel_tree);
        nodes_in_vessel = [];

        vessel = vessel_tree(vessel_index);
        for vessel_node_index = 1 : length(vessel.p);
            fprintf(fid, ' Node:% 8d\n', node_number);

            x = vessel.node_coords(vessel_node_index, 1);
            y = vessel.node_coords(vessel_node_index, 2);
            z = vessel.node_coords(vessel_node_index, 3);
            p = vessel.p(vessel_node_index);
            V = vessel.V(vessel_node_index);
            R = vessel.R(vessel_node_index);

            fprintf(fid, ['  ' FormatString(x) ' ' FormatString(y) ' ' FormatString(z) ' ' ...
                FormatString(p) ' ' FormatString(R) ' ' FormatString(V) '\n']);
            nodes_in_vessel = [nodes_in_vessel node_number];
            node_number = node_number + 1;
            
        end
        node_lists{vessel_index} = nodes_in_vessel;
    end

    fclose(fid);


    
function WriteElemFile(filename_prefix, vessel_tree, node_lists)

    initial_text_exelm = {
    ' Group name: vessel', ...
    ' Shape.  Dimension=1', ...
    ' #Scale factor sets= 1', ...
    '   l.Lagrange, #Scale factors= 2', ...
    ' #Nodes= 2', ...
    ' #Fields=4', ...
    ' 1) coordinates, coordinate, rectangular cartesian, #Components=3', ...
    '   x.  l.Lagrange, no modify, standard node based.', ...
    '     #Nodes= 2', ...
    '      1.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   1', ...
    '      2.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   2', ...
    '   y.  l.Lagrange, no modify, standard node based.', ...
    '     #Nodes= 2', ...
    '      1.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   1', ...
    '      2.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   2', ...
    '   z.  l.Lagrange, no modify, standard node based.', ...
    '     #Nodes= 2', ...
    '      1.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   1', ...
    '      2.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   2', ...
    ' 2) pressure, field, rectangular cartesian, #Components=1', ...
    '   pressure.  l.Lagrange, no modify, standard node based.', ...
    '     #Nodes= 2', ...
    '      1.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   1', ...
    '      2.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   2', ...
    ' 3) radius, field, rectangular cartesian, #Components=1', ...
    '   radius.  l.Lagrange, no modify, standard node based.', ...
    '     #Nodes= 2', ...
    '      1.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   1', ...
    '      2.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   2', ...
    ' 4) velocity, field, rectangular cartesian, #Components=1', ...
    '   velocity.  l.Lagrange, no modify, standard node based.', ...
    '     #Nodes= 2', ...
    '      1.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   1', ...
    '      2.  #Values=1', ...
    '       Value indices:     1', ...
    '       Scale factor indices:   2' ...
    };



    fid = fopen([filename_prefix '.exelem'],'w'); 

    for text = initial_text_exelm
       fprintf(fid, '%s\n', char(text)); 
    end

    element_number = 1;
    
    for vessel_index = 1 : length(vessel_tree)
        vessel_nodes = node_lists{vessel_index};
        for node_index = 1 : length(vessel_nodes) - 1
            this_node = vessel_nodes(node_index);
            next_node = vessel_nodes(node_index + 1);
            PrintOutElement(fid, element_number, this_node, next_node);
            element_number = element_number + 1;
        end
        connected_to = vessel_tree(vessel_index).connected_to;
        if (~isempty(connected_to))
            this_node = vessel_nodes(end);
            first_vessel = connected_to(1);
            second_vessel = connected_to(2);
            first_node_list = node_lists{first_vessel};
            first_node = first_node_list(1);    
            second_node_list = node_lists{second_vessel};
            second_node = second_node_list(1);
            PrintOutElement(fid, element_number, this_node, first_node);
            element_number = element_number + 1;
            PrintOutElement(fid, element_number, this_node, second_node);
            element_number = element_number + 1;            
        end
    end
    
    fclose(fid);

    
function PrintOutElement(fid, element_number, first_node, second_node)
    fprintf(fid, ' Element: % 6d 0 0\n', element_number);
    fprintf(fid, '   Nodes:\n');
    fprintf(fid, '     %6d %6d\n', first_node, second_node);
    fprintf(fid, '   Scale factors:\n');
    fprintf(fid, '       0.1000000000000000E+01   0.1000000000000000E+01\n');


function output_string = FormatString(number)
    output_string = sprintf('% 8.7E', number);


function vessel_tree = CalculateAllCoordinates(vessel_tree)
    for vessel_index = 1 : length(vessel_tree)
        vessel = vessel_tree(vessel_index);
        number_points = length(vessel.p);
        direction_vector = vessel.end_point - vessel.start_point;
        vessel_tree(vessel_index).node_coords = ones(number_points+1, 1)*vessel.start_point + ([0:number_points]')*direction_vector/(number_points-1);         
    end

function vessel_tree = CalculateStartAndEndpoints(vessel_tree)
    first_coordinate = [0, 0, 0];
    vessel_tree(1).start_point = first_coordinate;

    for i = 1 : length(vessel_tree)
        this_vessel = vessel_tree(i);
        start_point = this_vessel.start_point;
        angle = this_vessel.angle;
        end_point = start_point + this_vessel.length*[sin(angle), 0, cos(angle)];

        vessel_tree(i).start_point = start_point;
        vessel_tree(i).end_point = end_point;
        for vessel_to_index = this_vessel.connected_to
            vessel_tree(vessel_to_index).start_point = end_point;
        end
    end