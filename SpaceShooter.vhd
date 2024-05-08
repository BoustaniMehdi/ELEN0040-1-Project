library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity SpaceShooter is
    port (
		-- Inputs	
		clk_fast, clk_slow, move_left, move_right, shoot, control : in std_logic;
		
		-- Outputs
		
		-- Tricolor Matrix
		rows : out bit_vector(1 to 7);
		cols_green, cols_red : out bit_vector(1 to 5) := (others => '1');
		
		-- 7-segment display
		tens, unit: out std_logic_vector(3 downto 0) := (others => '0');
		
		-- RGB LED
		led_end: out std_logic

    );
end SpaceShooter;

architecture space_arch of SpaceShooter is
	
	-- Constants
	constant GRID_WIDTH : integer := 5;
	constant GRID_HEIGHT : integer := 7;
	constant OBSTACLE_SPEED_MAX : integer := 18;
	constant LIVES_MAX : integer := 3;
	constant MAX_SCORE : integer := 5;

	-- Game states
	type GameState is (MENU, PLAY, END_GAME, PAUSE);
	signal state : GameState := MENU;
	signal win : boolean := false;

	-- Player positions
	signal player_col : integer range 1 to GRID_WIDTH := 3;
	constant player_row : integer := GRID_HEIGHT;

	-- Game logic
	signal not_action : boolean := true; -- This boolean is false if a button has been pressed (moves, shoot & control)
	signal lives : integer range 0 to LIVES_MAX := LIVES_MAX; -- Number of lives of the player: 3 initially
	signal difficulty : integer range 1 to 3 := 1; -- Difficulty of the game

	-- Player shots
	signal bullet_row : integer range 0 to 6 := 6; -- Current row of the bullet fired by the player
	signal bullet : boolean := false; -- Indicates if our player has fired or not
	signal collision : boolean := false; -- Indicates if an obstacle has been hit or not

	-- Obstacles
	signal obstacle_row : integer range 1 to GRID_HEIGHT := 1; -- Vertical position of the obstacle
	signal obstacle_col : integer range 1 to GRID_WIDTH; -- Horizontal position of the obstacle
	signal obstacle_speed : integer range 1 to OBSTACLE_SPEED_MAX := OBSTACLE_SPEED_MAX; -- Speed of movement of the obstacle
	signal rand_col : integer range 1 to GRID_WIDTH := 1; -- Random column for the obstacle

	-- Facilitate matrix display according to current frequency
	signal counter : integer range 0 to 20; -- Index of the current line for the menu display
	signal switch : natural range 1 to 3; -- Switch for alternating between obstacles and the player

	-- 7 segments (0 to 50)
	signal tens_score : integer range 0 to MAX_SCORE;
	signal units_score : integer range 0 to 9;

	-- Controls the state of the RGB LED
	signal end_led_state : std_logic := '0';
	
	begin
		
		-- Game logic process responsible for managing the game's logic based on user input
   	logic : process(clk_slow, clk_fast, move_left, move_right, shoot, control)	
   	begin
      	if rising_edge(clk_slow) then
			
				case state is
				
					when MENU =>
					
						-- RESET
						led_end <= '0';
						tens_score <= 0;
						units_score <= 0;
						player_col <= 3;
						counter <= 0;
						win <= false;
						
						-- Cheking if the user pressed a button or not
						if(move_right = '0' and move_left = '0') then
							not_action <= true;
						
						-- Choosing the difficulty
						elsif(not_action) then
							not_action <= false;
							
							if move_left = '1' then
								if(difficulty > 1) then
									difficulty <= difficulty - 1;
								end if;
								
							elsif move_right = '1' then
								if(difficulty < 3) then
									difficulty <= difficulty + 1;
								end if;
							end if;
							
						end if;
						
						-- Initiating the game upon pressing the shoot button
						if(shoot = '1') then
							state <= PLAY;
						end if;
						
						-- During difficulty selection, only the units are utilized
						tens <= "0000";
						unit <= std_logic_vector(to_unsigned(difficulty, 4));
						
						-- Adjusting the game speed and number of lives based on the selected difficulty
						case difficulty is
							when 1 => 
								obstacle_speed <= OBSTACLE_SPEED_MAX;
								lives <= LIVES_MAX;
							when 2 =>
								obstacle_speed <= 12;
								lives <= LIVES_MAX;
							when 3 =>
								obstacle_speed <= 12;
								lives <= 1;
						end case;
						
					when PLAY =>
					
						-- Cheking if the user pressed a button or not
						if(move_right = '0' and move_left = '0' and shoot = '0') then
							not_action <= true;
							
						elsif(not_action) then
							not_action <= false;
							
							-- Move the player left
							if move_left = '1' then 
								if player_col > 1 then
									player_col <= player_col - 1;
								end if;
							
							-- Move the player right
							elsif move_right = '1' then
								if player_col < GRID_WIDTH then
										player_col <= player_col + 1;
								end if;
								
							-- Shoot
							elsif shoot = '1' then
								bullet <= true;
							end if;
							
						end if;
						
						-- Moves the bullet upward if the user fires
						if(bullet) then
							if(bullet_row > 1) then
								bullet_row <= bullet_row - 1;
							else
								bullet_row <= 6;
								bullet <= false;
							end if;
						end if;
						
						-- If the obstacle reaches the bottom of the matrix, reset its position and decrease a player's life
						if(obstacle_row = GRID_HEIGHT) then
							lives <= lives - 1;
							obstacle_row <= 1;
							obstacle_col <= rand_col;
							
						else
							-- If there is no collision, the obstacle can move downward
							if not collision then
								
								counter <= counter + 1;
								-- Move the obstacle downward according to the slowing down factor
								if counter = obstacle_speed then
									counter <= 0;
									obstacle_row <= obstacle_row + 1;
								end if;
								
							end if;
						end if;
						
						
						if(collision) then
						
							-- Manually increment the score to save logic gates (optimization)
							if units_score = 9 then
								tens_score <= tens_score + 1;
								obstacle_speed <= obstacle_speed - 2;
								units_score <= 0;
							else
								units_score <= units_score + 1;
							end if;
							
							-- Reset the obstacle and the bullet
							obstacle_row <= 1;
							obstacle_col <= rand_col;
							bullet <= false;
							bullet_row <= 6;
							
						end if;
						
						
						-- Update the 7-segment display based on the score
						tens <= std_logic_vector(to_unsigned(tens_score, 4));
						unit <= std_logic_vector(to_unsigned(units_score, 4));
						
						if(lives = 0) then
							state <= END_GAME;
						end if;

						if(control = '1') then
							state <= PAUSE;
						end if;
						
						-- The user reached the final score
						if(tens_score = MAX_SCORE) then
							win <= true;
							state <= END_GAME;
						end if;
						
						
					when END_GAME =>
						
						-- If the user won, the RGB LED blinks in red
						if(win) then
							counter <= counter + 1;
							if(counter = 20) then
								counter <= 0;
								end_led_state <= not end_led_state;
								led_end <= end_led_state;
							end if;
						-- If the user lost, the RGB LED is continuously red
						else
							led_end <= '1';
						end if;
						
						if(control = '1') then
							state <= MENU;
						end if;
						
					when PAUSE =>
					
						-- Press the shoot button to resume the game
						if(shoot = '1') then
							state <= PLAY;
						end if;
						
				end case;
			end if;
		end process logic;
   
	-- Random process for the obstacle column
	random : process(clk_fast)
	begin 
		if rising_edge(clk_fast) then
			if rand_col = GRID_WIDTH then
				rand_col <= 1;
			else
				rand_col <= rand_col + 1;
			end if;
		end if;
	end process random;
	
	-- Display process to show elements on the tricolor matrix
	display : process(clk_fast, control)   
	begin
	
	  if rising_edge(clk_fast) then
			case state is
				when PLAY | PAUSE =>
					 rows <= (others => '0');
					 cols_green <= (others => '1');
					 cols_red <= (others => '1');
					 
					 collision <= ((((bullet_row - 1 = obstacle_row) or bullet_row = obstacle_row) and player_col = obstacle_col) and bullet); -- Si le tir a touché un obstacle, il vaut true. False sinon
					 
					 case switch is
					 
					   -- On the first rising edge, display the player according to their state
						when 1 =>
							
							-- Determine the player's display color based on the number of lives (3 -> Green, 2 -> Orange, 1 -> Red)
							case lives is 
								when LIVES_MAX => 
									 cols_green(player_col) <= '0';
								when 2 => 
									 cols_green(player_col) <= '0';
									 cols_red(player_col) <= '0';
								when 1 => 
									 cols_red(player_col) <= '0';
								when others =>
							end case;
							
							-- Displaying only the player's row
							rows(player_row) <= '1';
					 
						-- On the second rising edge, display the obstacle
						when 2 =>
							
							cols_red <= (others => '1');
							rows <= (others => '0');
							rows(obstacle_row) <= '1';
							cols_red(obstacle_col) <= '0';
				 
						-- On the third rising edge, display the player's shot if fired
						when 3 =>
							if bullet then
								rows(bullet_row) <= '1';
								cols_red(player_col) <= '0';
							end if;
							
					end case;
					
					switch <= switch + 1;
					
				when END_GAME =>
				
					-- Activate all lines of the tricolor matrix
					rows <= (others => '1');
					
					-- Suppress the display of the next obstacle
					cols_red(obstacle_col) <= '1';
					
					-- Display the tricolor matrix in green if the user wins, red if he loses
					if(win) then	
						cols_green <= (others => '0');
					else
						cols_green <= (others => '1');	
						cols_red <= (others => '0');	
					end if;
					
				when others =>
				
					-- Reset the tricolor matrix when the user is in the menu
					rows <= (others => '0');
					cols_green <= (others => '1');
					cols_red <= (others => '1');
					
			end case;
	  end if;
	end process display;

end architecture space_arch;
