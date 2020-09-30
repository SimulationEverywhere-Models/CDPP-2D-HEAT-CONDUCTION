     '***************************************
     '*         PROGRAM  HEAT2D2            *
     '*   HEAT 2-D  WITH 3-NODED TRIANGLES  *
     '* T.R.Chandrupatla and A.D.Belegundu  *
     '***************************************
     DEFINT I-N: CLS : COLOR 1, 3
     LOCATE 1, 1: PRINT "HEAT-2D WITH TRIANGLES  "; SPACE$(23);
     PRINT "(C)  Chandrupatla & Belegundu": : COLOR 7, 0
     PRINT : INPUT "File Name for Input Data ", FILE1$
     OPEN FILE1$ FOR INPUT AS #2
     LINE INPUT #2, D$: INPUT #2, TITLE$: LINE INPUT #2, D$
     INPUT #2, NN, NE, NM, NDIM, NEN, NDN
     LINE INPUT #2, D$
     INPUT #2, ND, NL, II, NPR, NMPC
     NPR = 1: NMPC = 0
     '--- ND = NO. OF SPECIFIED TEMPERATURES
     '--- NL = NO. OF NODAL HEAT SOURCES
     'NOTE!!  NPR =1 (THERMAL CONDUCTIVITY) AND NMPC = 0 FOR THIS PROGRAM
     '--- EHS(I) = ELEMENT HEAT SOURCE, I = 1,...,NE
     INPUT "File Name for Output ", FILE2$
     DIM X(NN, 2), NOC(NE, 3), MAT(NE), PM(NM, NPR), F(NN)
     DIM NU(ND), U(ND), EHS(NE)
     OPEN FILE2$ FOR OUTPUT AS #1
     PRINT
     PRINT "      PLOT CHOICE"
     PRINT "  1) No Plot Data"
     PRINT "  2) Create Data File Containing Nodal Temperatures"
     INPUT "     Choose 1 or 2 "; IPL
     IF IPL < 1 OR IPL > 2 THEN IPL = 1   '--- default is no data
     IF IPL = 2 THEN
       INPUT "File Name for Plot Data "; FILE3$
       OPEN FILE3$ FOR OUTPUT AS #3
     END IF
     '----- Coordinates
     INPUT #2, D$
     FOR I = 1 TO NN
        INPUT #2, N
        FOR J = 1 TO NDIM
           INPUT #2, X(N, J)
        NEXT J
     NEXT I
     '----- Connectivity, Material#, Element Heat Source
     INPUT #2, D$
     FOR I = 1 TO NE
        INPUT #2, N
        FOR J = 1 TO NEN
           INPUT #2, NOC(N, J)
        NEXT J
        INPUT #2, MAT(N), EHS(N)
     NEXT I
     '----- Temperature BC
     LINE INPUT #2, D$
     FOR I = 1 TO ND: INPUT #2, NU(I), U(I): NEXT I
     '----- Nodal Heat Sources
     LINE INPUT #2, D$
     FOR I = 1 TO NN: F(I) = 0: NEXT I
     FOR I = 1 TO NL: INPUT #2, N, F(N): NEXT I
     '----- Thermal Conductivity of Material
     INPUT #2, D$
     FOR I = 1 TO NM
        INPUT #2, N
        FOR J = 1 TO NPR
           INPUT #2, PM(N, J)
        NEXT J
     NEXT I
     '--- BAND WIDTH CALCULATION ---
     IDIFF = 0
     FOR K = 1 TO NE
        FOR I = 1 TO 2
           FOR J = I + 1 TO 3
              II = ABS(NOC(K, J) - NOC(K, I))
              IF II > IDIFF THEN IDIFF = II
           NEXT J
        NEXT I
     NEXT K
     NBW = IDIFF + 1
     PRINT #1, "THE BAND WIDTH IS"; NBW
     '--- INITIALIZATION OF CONDUCTIVITY MATRIX AND HEAT RATE VECTOR
     DIM S(NN, NBW)
     FOR I = 1 TO NN
        FOR J = 1 TO NBW
           S(I, J) = 0
        NEXT J
     NEXT I
     INPUT #2, D$
     INPUT #2, NHF
     IF NHF > 0 THEN
       FOR I = 1 TO NHF
          INPUT #2, N1, N2, V
          ELEN = SQR((X(N1, 1) - X(N2, 1)) ^ 2 + (X(N1, 2) - X(N2, 2)) ^ 2)
          F(N1) = F(N1) - ELEN * V / 2
          F(N2) = F(N2) - ELEN * V / 2
       NEXT I
     END IF
     INPUT #2, D$
     INPUT #2, NCONV
     IF NCONV > 0 THEN
       FOR I = 1 TO NCONV
          INPUT #2, N1, N2, H, TINF
          ELEN = SQR((X(N1, 1) - X(N2, 1)) ^ 2 + (X(N1, 2) - X(N2, 2)) ^ 2)
          F(N1) = F(N1) + ELEN * H * TINF / 2
          F(N2) = F(N2) + ELEN * H * TINF / 2
          S(N1, 1) = S(N1, 1) + H * ELEN / 3
          S(N2, 1) = S(N2, 1) + H * ELEN / 3
          IF N1 >= N2 THEN
             N3 = N1: N1 = N2: N2 = N3
          END IF
          S(N1, N2 - N1 + 1) = S(N1, N2 - N1 + 1) + H * ELEN / 6
       NEXT I
     END IF
     CLOSE #2
     '--- CONDUCTIVITY MATRIX
     DIM BT(2, 3)
     FOR I = 1 TO NE
        I1 = NOC(I, 1): I2 = NOC(I, 2): I3 = NOC(I, 3)
        X32 = X(I3, 1) - X(I2, 1): X13 = X(I1, 1) - X(I3, 1)
        X21 = X(I2, 1) - X(I1, 1)
        Y23 = X(I2, 2) - X(I3, 2): Y31 = X(I3, 2) - X(I1, 2)
        Y12 = X(I1, 2) - X(I2, 2)
        DETJ = X13 * Y23 - X32 * Y31
        AREA = .5 * ABS(DETJ)
        '--- ELEMENT HEAT SOURCES
        IF EHS(I) <> 0 THEN
           C = EHS(I) * AREA / 3
           F(I1) = F(I1) + C: F(I2) = F(I2) + C: F(I3) = F(I3) + C
        END IF
        BT(1, 1) = Y23: BT(1, 2) = Y31: BT(1, 3) = Y12
        BT(2, 1) = X32: BT(2, 2) = X13: BT(2, 3) = X21
        FOR II = 1 TO 3
           FOR JJ = 1 TO 2
              BT(JJ, II) = BT(JJ, II) / DETJ
           NEXT JJ
        NEXT II
        FOR II = 1 TO 3
           FOR JJ = 1 TO 3
              II1 = NOC(I, II): II2 = NOC(I, JJ)
              IF II1 <= II2 THEN
                 SUM = 0
                 FOR J = 1 TO 2
                    SUM = SUM + BT(J, II) * BT(J, JJ)
                 NEXT J
                 IC = II2 - II1 + 1
                 S(II1, IC) = S(II1, IC) + SUM * AREA * PM(MAT(I), 1)
              END IF
           NEXT JJ
        NEXT II
     NEXT I
     IF ND > 0 THEN
       '--- MODIFY FOR TEMP. BOUNDARY CONDITIONS
       SUM = 0
       FOR I = 1 TO NN
          SUM = SUM + S(I, 1)
       NEXT I
       SUM = SUM / NN
       CNST = SUM * 1000000
       FOR I = 1 TO ND
          N = NU(I)
          S(N, 1) = S(N, 1) + CNST
          F(N) = F(N) + CNST * U(I)
       NEXT I
     END IF
     '--- EQUATION SOLVING
     N = NN
     GOSUB BANSOL
     PRINT #1, "NODE NO., TEMPERATURES"
     PRINT : PRINT "NODE NO., TEMPERATURES"
     FOR I = 1 TO NN
        PRINT #1, I, F(I)
        PRINT I, F(I)
     NEXT I
     IF IPL = 2 THEN
       PRINT #3, "Nodal Temperatures "
       FOR I = 1 TO NN: PRINT #3, F(I): NEXT I
       CLOSE #3
       PRINT
       PRINT : PRINT "Nodal Temperature Data in file "; FILE3$
       PRINT "Run CONTOUR1 or CONTOUR2 to plot isotherms"
     END IF
     PRINT #1, " ** CONDUCTION HEAT FLOW PER UNIT AREA IN EACH ELEMENT ** "
     PRINT #1, "ELEMENT#   QX= -K*DT/DX    QY= -K*DT/DY "
     FOR I = 1 TO NE
        I1 = NOC(I, 1): I2 = NOC(I, 2): I3 = NOC(I, 3)
        X32 = X(I3, 1) - X(I2, 1): X13 = X(I1, 1) - X(I3, 1)
        X21 = X(I2, 1) - X(I1, 1)
        Y23 = X(I2, 2) - X(I3, 2): Y31 = X(I3, 2) - X(I1, 2)
        Y12 = X(I1, 2) - X(I2, 2)
        DETJ = X13 * Y23 - X32 * Y31
        BT(1, 1) = Y23: BT(1, 2) = Y31: BT(1, 3) = Y12
        BT(2, 1) = X32: BT(2, 2) = X13: BT(2, 3) = X21
        FOR II = 1 TO 3
           FOR JJ = 1 TO 2
              BT(JJ, II) = BT(JJ, II) / DETJ
           NEXT JJ
        NEXT II
        QX = BT(1, 1) * F(I1) + BT(1, 2) * F(I2) + BT(1, 3) * F(I3)
        QX = -QX * PM(MAT(I), 1)
        QY = BT(2, 1) * F(I1) + BT(2, 2) * F(I2) + BT(2, 3) * F(I3)
        QY = -QY * PM(MAT(I), 1)
        PRINT #1, I, QX, QY
     NEXT I
     END
BANSOL:
     '--- FORWARD ELIMINATION
     FOR K = 1 TO N - 1
        NBK = N - K + 1
        IF N - K + 1 > NBW THEN NBK = NBW
        FOR I = K + 1 TO NBK + K - 1
           I1 = I - K + 1
           C = S(K, I1) / S(K, 1)
           FOR J = I TO NBK + K - 1
              J1 = J - I + 1
              J2 = J - K + 1
              S(I, J1) = S(I, J1) - C * S(K, J2)
           NEXT J
           F(I) = F(I) - C * F(K)
        NEXT I
     NEXT K
     '--- BACK SUBSTITUTION ---
     F(N) = F(N) / S(N, 1)
     FOR II = 1 TO N - 1
        I = N - II
        NBI = N - I + 1
        IF N - I + 1 > NBW THEN NBI = NBW
        SUM = 0
        FOR J = 2 TO NBI
           SUM = SUM + S(I, J) * F(I + J - 1)
        NEXT J
        F(I) = (F(I) - SUM) / S(I, 1)
     NEXT II
     '--- F CONTAINS THE SOLUTION. 'S' IS OVER-WRITTEN
     RETURN


