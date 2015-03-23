function removal = forwardflight( Vf0, Vf1 )
% FORWARDFLIGHT
%     forwardflight( Vc0, Vc1 ) is a co-function with QUADAnalyser. The main 
%     propose of this function is to fugure out the
%     minimum power, minimun power required R/C and maximun R/C in the
%     specified condition. In this functtion, you have to input the 


% AUTHOOR INFORMACTIONS
%     Date : 24-Mar-2015 03:24:46
%     Author : Wei-Chieh Chang
%     Degree : M. Eng. Dept. Of Aerospace Engineering Tamkang University
%     Version : 4.2
%     Copyright 2015 by Avionics And Flight Simulation Laboratory


global FM Nu SizeM LengM CounterFig CounterGeh
global GeoHeight AirDensity Power Gravity TotalMass Weight 
global RoterArea RotorNumber RotorRadious Sref1 Sref2 CD1 CD2

if nargin == 0
    Vf0 = 0.5;
    Vf1 = 20;
elseif nargin == 1
    Vf1 = 20;
end    
    
% Declare a row data for forward speed. From Vf0 to Vf1, divid into 1000
% steps. 
Vf = linspace( Vf0, Vf1, 100 );

% Ther process to computing the power required for each term. The power
% avaliable is derived from the momentum method. With the forward speed 
% increase, the thrust avaliable will decrease. The propeller power is the 
% power which dispat at propeller, the parasite is the power to elimiate the 
% drag. Thus, the total power is the summation of propeller and parasite
% power. Notice that, the power avaliable will be a constant. 
PowerAva = Power .* ones( size( Vf ) );

for i = 1: 1: LengM
    
    % The induced velocity in hoveing, deriving from momemtum method.
    V1h( i, 1 ) = sqrt( Weight( i, 1 ) / ( 2 * AirDensity( i, 1 ) * RotorNumber * RoterArea ) );
    
    % The function quadpitch( Vf ) is a function to figure out the pitch
    % angle of the quadrotor. Notice that, just for steady flight. The
    % definition for steady flight is mean thoese forces act on quadrotor is
    % elimiated by each other which at same axis.
    
    % Determinate the drag by standard drag equation.
    DragPitch( i, : ) = 0.5 * AirDensity( i, 1 ) .* ( Vf.^2 ) .* CD1 * Sref1 ...
        +  0.5 * AirDensity( i, 1 ) .* ( Vf.^2 ) .* CD2 * Sref2;
    
    %
    TremPitch( i, : ) =  Weight( i, 1 ) ./ DragPitch( i, : );
    
    % Pitch angle estiamtion, if you want know more detail, please check my
    % master thesis. There have more dissucss.
    theta( i, : ) = asin( ( -TremPitch( i, : ) + sqrt( 4 + TremPitch( i, : ).^2 ) ) ./ 2 );
    
    % Here have three methods to figure out the induced velocity at propeller,
    % first method is based on my theory, but it still need be approved by my
    % thesis advisor. The second is to calculate the induced veloctity on
    % helicopter. The equation is exact solution. The third is an approximation
    % solution.
    Methods = 1;
    if Methods == 1
        V1f( i, : ) = sqrt( - ( Vf.^2 / 2 ) + ...
                        sqrt( ( Vf.^2 / 2 ).^2 + V1h( i, 1 )^4 ) );
    elseif Methods == 2
        V1f( i, : ) = -0.5 .* Vf .* sin( theta( i, : ) ) + ...
                        sqrt( ( 0.5 .* Vf .* sin( theta( i, : ) ) ).^2 + V1h( i, 1 )^2 );
    elseif Methods == 3
        V1f( i, : ) = ( V1h^2 ) ./ Vf;
    end

    % Calculate the nacessary thrust of the quadrotor which provided by
    % propeller. The equation is derived from the force diagram. The Parasite
    % drag is base on standard drag equation.
    DragParasi( i, : ) = 0.5 * AirDensity( i, 1 ) .* ( Vf.^2 ) ...
                            .* CD1 * Sref1 .* sin( theta( i, : ) );
    DragParasi2( i, : ) = 0.5 * AirDensity( i, 1 ) .* ( 2 .* V1f( i, : ) +...
                            Vf .* sin( theta( i, : ) ) ).^2  * CD2 * Sref2;
                        
    % Calculate the nacessary thrust of the quadrotor which provided by
    % propeller. The equation is derived from the force diagram.                  
    ThrustReqX( i, : ) = DragParasi( i, : ) + ...
                         DragParasi2( i, : ) .* sin( theta( i, : ) );
    ThrustReqY( i, : ) = Weight( i, 1 ) + ...
                         DragParasi2( i, : ) .* cos( theta( i, : ) );
    ThrustReqF( i, : ) = sqrt( ThrustReqX( i, : ).^2 + ThrustReqY( i, : ).^2 );
    ThrustAvaF( i, : ) = FM .* PowerAva ./ ( V1f( i, : ) + Vf .* sin( theta( i, : ) ) );
    ThrustExcF( i, : ) = ThrustAvaF( i, : ) - ThrustReqF( i, : );
    
    % Here are algorithms with different view.
    ProMethod = 1;
    if ProMethod == 1
        PowerPro( i, : ) = ( ThrustReqF( i, : ) .* ...
                           ( V1f( i, : ) + Vf .* sin( theta( i, : ) ) ) ./ FM );
    elseif ProMethod == 2
        PowerPro( i, : ) = ( ThrustReqF( i, : ) .* ...
                           ( V1f( i, : ) + Vf ) ./ FM );
    elseif ProMethod == 3
        PowerPro( i, : ) = ( ThrustReqF( i, : ) .* ...
                           V1f( i, : ) ./ FM );
    end
    
    % The process to figure out parasite power, propeller power
    %PowerPra( i, : ) = 0.5 * AirDensity * Sref1 * CD1 .*  Vf.^3  ;
    PowerPra( i, : ) = DragParasi( i, : ) .* Vf + ...
                       DragParasi2( i, : ) .* ( 2 .* V1f( i, : ) );
    PowerReq( i, : ) = PowerPro( i, : ) + PowerPra( i, : );
    PowerExc( i, : ) = PowerAva - PowerReq( i, : );
    PowerOpr( i, : ) = Vf ./ PowerReq( i, : );
    
    if( PowerExc( i, 1 ) <= 0 )
        OPTFW( i, 1 ) = 0;
        OPRFW( i, 1 ) = 0;
        MAXFW( i, 1 ) = 0;
    else
        % Seek the value and the address of minimum power required, where the
        % PowerAmp is the value and PowerLoc is the address. Using the address to
        % compare where the corresponding velocity is.
        [ PowerAmp( i, 1 ) PowerLoc( i, 1 ) ] = min( PowerReq( i, : ) );
        [ OprvfAmp( i, 1 ) OprvfLoc( i, 1 ) ] = max( PowerOpr( i, : ) );
        
        % Seek the valus and address for excess power.
        [ MaxrcAmp( i, 1 ) MaxrcLoc( i, 1 ) ] = min( abs( PowerExc( i, : ) ) );
        
        % The final answer for quadrotor perforamce parameters while in forward
        % flight. The detail shows as the following:
        % OPTFW : Optimal forward speed for minimum power.
        % OPRFW : Optimal forward speed for maximum range.
        % PORFW : The value power required.
        % MAXFW : The maximun forward speed.
        % EXCFW : The maximum excess power.
        OPTFW( i, 1 ) = Vf( PowerLoc( i, 1 ) );
        OPRFW( i, 1 ) = Vf( OprvfLoc( i, 1 ) );
        MAXFW( i, 1 ) = Vf( MaxrcLoc( i, 1 ) );
        PORFW( i, 1 ) = PowerAmp( i, 1 );
        POPRFW( i, 1 ) = OprvfAmp( i, 1 );
        EXCFW( i, 1 ) = Power - PowerAmp( i, 1 );
        
    end
    
end

% Plot the figure 
figure( CounterFig );
CounterFig = CounterFig +1;
plot( Vf, PowerPra( CounterGeh, : ), 'g',...
       Vf, PowerPro( CounterGeh, : ), 'b',...
       Vf, PowerReq( CounterGeh, : ), 'r',...
       Vf, PowerAva, 'm');
title( { [ ' Power Required in Forward Flight ' ];
         [ ' At ' num2str( GeoHeight( CounterGeh, 1 ) ) ' m height ' ] } );
legend( 'Parasite', 'Propeller', 'Required', 'Avaliable')
xlabel( ' Forwrad Speed (m/s) ' );
ylabel( ' Power Required (W) ' );
grid on;

% Plot the figure 
figure( CounterFig );
CounterFig = CounterFig +1;
plot( Vf, PowerExc( CounterGeh, : ) );
title( { [ ' Excess Power in Forward Flight ' ];
         [ ' At ' num2str( GeoHeight( CounterGeh, 1 ) ) ' m height ' ] } );
xlabel( ' Forwrad Speed (m/s) ' );
ylabel( ' Power Required (W) ' );
grid on;

% Plot the figure 
figure( CounterFig );
CounterFig = CounterFig +1;
plot( Vf, PowerOpr( CounterGeh, : ) );
title( { [ ' Maximum Range Forward Speed ' ];
         [ ' At ' num2str( GeoHeight( CounterGeh, 1 ) ) ' m height ' ] } );
xlabel( ' Forwrad Speed (m/s) ' );
ylabel( ' Power consuption (m/W)' );
grid on

removal = 0;
% 
% % Figure polt
% figure( 8 )
% plot( Vf, rad2deg( theta ) );
% title( ' Pitch Angle in Forward Flight  ' );
% xlabel( ' Forwrad Speed (m/s) ' );
% ylabel( ' Pitch Angle (Deg.) ' );
% grid on
% 
% % Figure polt
% figure( 8 )
% plot( Vf, ThrustReqF );
% title( ' Thrust Required in Forward Flight  ' );
% xlabel( ' Forwrad Speed (m/s) ' );
% ylabel( ' Thrust Required (N) ' );
% grid on
% 
% % Figure polt
% figure( 9 )
% plot( Vf, ThrustAvaF, '--r', Vf, ThrustExcF );
% title( ' Thrust Ava in Forward Flight  ' );
% xlabel( ' Forwrad Speed (m/s) ' );
% ylabel( ' Thrust Required (N) ' );
% grid on
% 
% % Figure polt
% figure( 10 )

% %
% {[ 'Opt. FW = ' num2str( round( OPTFW ) ) ' m/s ' ];
%  [ 'Opr. FW = ' num2str( round( OPRFW ) ) ' m/s ' ];   
%  [ 'Min. P.R = ' num2str( round( PORFW ) ) ' W   ' ];
%  [ 'Max. FW = ' num2str( round( MAXFW ) ) ' m/s ' ]}

