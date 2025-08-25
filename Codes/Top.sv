`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.08.2025 10:01:55
// Design Name: Top
// Module Name: Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top(

    input logic clk,rst,
    
    //Floor selection wires
    input logic [3:0] floor_sel_in,
    
    //Groung floor
    input logic up_gnd_in,
    output logic out_gnd,
    
    //First floor
    input logic up_one_in,down_one_in,
    output logic out_one,
    
    //Second floor
    input logic up_two_in,down_two_in,
    output logic out_two,
    
    //Third floor - Top floor
    input logic down_three_in,
    output logic out_three

    );
    
    // This logic will tell if the lift is going up or down
    logic up,down;
    logic [3:0]final_dest;
    
    logic [3:0] floor_sel;
    
    //Counter to show the lift stopped
    logic stop;
    
    //floor declearations
    typedef enum logic[2:0]{ground,first,second,third} floors;
    floors curr_floor,next_floor;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_floor <= ground;
            next_floor <= ground;
            floor_sel  <= 4'b0;
        end else begin
            curr_floor <= next_floor;
            
            if (floor_sel[0] && curr_floor == ground) floor_sel[0] <= 1'b0;
            else if (floor_sel_in[0]) floor_sel[0] <= 1'b1;
            if (floor_sel[1] && curr_floor == first)  floor_sel[1] <= 1'b0;
            else if (floor_sel_in[1]) floor_sel[1] <= 1'b1;
            if (floor_sel[2] && curr_floor == second) floor_sel[2] <= 1'b0;
            else if (floor_sel_in[2]) floor_sel[2] <= 1'b1;
            if (floor_sel[3] && curr_floor == third)  floor_sel[3] <= 1'b0;
            else if (floor_sel_in[3]) floor_sel[3] <= 1'b1;
        end
    end


    //Internal wires
    logic up_gnd, up_one, down_one, up_two, down_two, down_three;
    
    //Clear requestes once served
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            up_gnd    <= 1'b0;
            up_one    <= 1'b0;
            down_one  <= 1'b0;
            up_two    <= 1'b0;
            down_two  <= 1'b0;
            down_three<= 1'b0;
        end else begin
            // Set requests when button pressed
            if (up_gnd_in)    up_gnd    <= 1'b1;
            if (up_one_in)    up_one    <= 1'b1;
            if (down_one_in)  down_one  <= 1'b1;
            if (up_two_in)    up_two    <= 1'b1;
            if (down_two_in)  down_two  <= 1'b1;
            if (down_three_in)down_three<= 1'b1;
    
            // Clear requests once served (lift reached + direction matches)
            if ((curr_floor == ground) && stop)   up_gnd    <= 1'b0;
            if ((curr_floor == first)  && stop) begin
                if (up)   up_one   <= 1'b0;
                if (down) down_one <= 1'b0;
            end
            if ((curr_floor == second) && stop) begin
                if (up)   up_two   <= 1'b0;
                if (down) down_two <= 1'b0;
            end
            if ((curr_floor == third) && stop)    down_three <= 1'b0;
        end
    end


    
    //To set final_dest
    always_comb begin
        if (up) begin
            if (down_three || floor_sel[3]) final_dest = 4'b1000;
            else if (up_two || floor_sel[2]) final_dest = 4'b0100;
            else if (up_one || floor_sel[1]) final_dest = 4'b0010;
            else if (up_gnd || floor_sel[0]) final_dest = 4'b0001;
            else final_dest = 4'b0;
        end 
        else if (down) begin
            if (up_gnd || floor_sel[0]) final_dest = 4'b0001;
            else if (down_one || floor_sel[1]) final_dest = 4'b0010;
            else if (down_two || floor_sel[2]) final_dest = 4'b0100;
            else if (down_three || floor_sel[3])final_dest = 4'b1000;
            else final_dest = 4'b0;
        end 
        else begin
            if (up_gnd) final_dest = 4'b0001;
            else if (down_one || up_one) final_dest = 4'b0010;
            else if (down_two || up_two) final_dest = 4'b0100;
            else if (down_three)final_dest = 4'b1000;
            else final_dest = 4'b0;
        end
    end


    //Floor traveling
    always@* begin
        case(curr_floor)
            ground : begin
                // Serve local requests first
                if (up_gnd || floor_sel[0] || final_dest[0]) begin
                    stop = 1'b1;           // open doors
                    next_floor = ground;
                end 
        
                // If already stopped, check global destination
                else if (stop) begin
                    if (|floor_sel[3:1] || |final_dest[3:1]) begin
                        // Someone requested a higher floor
                        up = 1'b1;
                        down = 1'b0;
                        next_floor = first;
                        stop  = 1'b0;       // close doors and start moving
                    end else begin
                        // No requests anywhere, stay idle at ground
                        up = 1'b0;
                        down = 1'b0;
                        next_floor = ground;
                        stop  = 1'b1;       // idle with doors open
                    end
                end
                else begin
                    //Going up
                    if(|final_dest[3:1]) begin
                        next_floor = first;
                        
                        stop  = 1'b0;
                        up = 1'b1;
                        down = 1'b0;
                    end
                end
            end
            first : begin
                // Serve local requests first
                //Stop only when going up
                if ((up_one || floor_sel[1] || final_dest[1]) && up) begin
                    stop = 1'b1;           // open doors
                    next_floor = first;
                end 
                //Stop only when going down
                else if ((down_one || floor_sel[1] || final_dest[1]) && down) begin
                    stop = 1'b1;           // open doors;
                    next_floor = first;
                end 
                // If already stopped, check global destination
                else if (stop) begin
                    // Someone requested a higher floor
                    if (|floor_sel[3:2] || |final_dest[3:2]) begin
                        up = 1'b1;
                        down = 1'b0;
                        next_floor = second;
                        stop  = 1'b0;       // close doors and start moving
                    end 
                    // Someone requested a lower floor
                    else if (floor_sel[0] || final_dest[0]) begin
                        up = 1'b0;
                        down = 1'b1;
                        next_floor = ground;
                        stop  = 1'b0;       // close doors and start moving
                    end
                    else begin
                        // No requests anywhere, stay idle at ground
                        up = 1'b0;
                        down = 1'b0;
                        next_floor = first;
                        stop  = 1'b1;       // idle with doors open
                    end
                end
                // If didn't stop and just in moving
                else begin
                    //Going up
                    if(up && (|final_dest[3:2]))
                        next_floor = second;
                    else if (down && final_dest[0])
                        next_floor = ground;
                    else
                        next_floor <= first;
                end
            end
        second: begin
            // Serve local requests first
            // Stop only when going up
            if ((up_two || floor_sel[2] || final_dest[2]) && up) begin
                stop = 1'b1;       // open doors
                next_floor = second;
            end
            // Stop only when going down
            else if ((down_two || floor_sel[2] || final_dest[2]) && down) begin
                stop = 1'b1;       // open doors
                up = 1'b0;
                down = 1'b0;
                next_floor = second;
            end
            // If already stopped, check global destination
            else if (stop) begin
                // Someone requested a higher floor
                if (floor_sel[3] || final_dest[3]) begin
                    up = 1'b1;
                    down = 1'b0;
                    next_floor = third;
                    stop = 1'b0;   // close doors and start moving
                end
                // Someone requested a lower floor
                else if (|floor_sel[1:0] || |final_dest[1:0]) begin
                    up = 1'b0;
                    down = 1'b1;
                    next_floor = first;
                    stop = 1'b0;   // close doors and start moving
                end
                else begin
                    // No requests anywhere ? idle at second floor
                    up = 1'b0;
                    down = 1'b0;
                    next_floor = second;
                    stop = 1'b1;   // doors open
                end
            end
            // If didn't stop and just moving
            else begin
                if (up && final_dest[3])
                    next_floor = third;
                else if (down && |final_dest[1:0])
                    next_floor = first;
                else
                    next_floor = second;  // stay if no requests
            end
        end
        third: begin
            // Serve local requests first
            if (down_three || floor_sel[3] || final_dest[3]) begin
                stop = 1'b1;       // open doors
                next_floor = third;
            end
        
            // If already stopped, check global requests
            else if (stop) begin
                if (|floor_sel[2:0] || |final_dest[2:0]) begin
                    // Someone requested a lower floor
                    up = 1'b0;
                    down = 1'b1;
                    next_floor = second;
                    stop = 1'b0;   // close doors and start moving
                end
                else begin
                    // No requests anywhere ? idle at third floor
                    up = 1'b0;
                    down = 1'b0;
                    next_floor = third;
                    stop = 1'b1;   // doors open
                end
            end
        end
        endcase 
    
    end   
    
    //Assign outputs
    assign out_gnd   = (curr_floor == ground);
    assign out_one   = (curr_floor == first);
    assign out_two   = (curr_floor == second);
    assign out_three = (curr_floor == third);
    
endmodule
