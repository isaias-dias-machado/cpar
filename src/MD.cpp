/*
 MD.c - a simple molecular dynamics program for simulating real gas properties
 of Lennard-Jones particles.

 Copyright (C) 2016  Jonathan J. Foley IV, Chelsea Sweet, Oyewumi Akinfenwa

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 Electronic Contact:  foleyj10@wpunj.edu
 Mail Contact:   Prof. Jonathan Foley
 Department of Chemistry, William Paterson University
 300 Pompton Road
 Wayne NJ 07470

 */

/*
 * ASSIGNMENT:
 * The program to analyse and optimise is one simple molecular dynamics’
 * simulation code applied to atoms of argon gas. The original code was taken
 * from FoleyLab/MolecularDynamics: Simple Molecular Dynamics, slightly modified
 * for this course context. On this first phase, students are requested to
 * develop an OpenMP parallel version of the code supplied in the course
 * e-Learning page. The code follows a generic approach to simulate particle
 * movements over time steps, using the Newton law. It uses Lennard Jones
 * potential to describe the interactions among two particles (force/potential
 * energy). The Verlet integration method is used to calculate the particles
 * trajectories over time. Boundary conditions (i.e., particles moving outside
 * the simulation space) are managed by elastic walls (see supporting slides on
 * the e-Learning page)*
 */

#include <arm_sve.h>
#include <stdint.h>

#include <cstdlib>
#include <math.h>
#include <stdio.h>
#include <string.h>

#include <omp.h>

// Number of particles
int N;

//  Lennard-Jones parameters in natural units!
double sigma = 1.;
double epsilon = 1.;
double m = 1.;
double kB = 1.; // representative Boltzmann constant

// Potential energy, filled by computeAccelerations()
double Epot = 0.;

double NA = 6.022140857e23;   // mole = quantity of particles
double kBSI = 1.38064852e-23; // m^2*kg/(s^2*K)

//  Size of box, which will be specified in natural units
double L;

//  Initial Temperature in Natural Units
double Tinit; // 2;
//  Vectors!
//
const int MAXPART = 5001;
//  Position
double r[MAXPART][3];
//  Velocity
double v[MAXPART][3];
//  Acceleration
double a[MAXPART][3];
//  Force
double F[MAXPART][3];

alignas(256) double rx[MAXPART];
alignas(256) double ry[MAXPART];
alignas(256) double rz[MAXPART];

// atom type
char atype[10];
//  Function prototypes
//  initialize positions on simple cubic lattice, also calls function to
//  initialize velocities
void initialize();
//  update positions and velocities using Velocity Verlet algorithm
//  print particle coordinates to file for rendering via VMD or other animation
//  software return 'instantaneous pressure'
double VelocityVerlet(double dt, int iter, FILE *fp);
//  Compute Force using F = -dV/dr
//  solve F = ma for use in Velocity Verlet
void computeAccelerations();
//  Numerical Recipes function for generation gaussian distribution
double gaussdist();
//  Initialize velocities according to user-supplied initial Temperature (Tinit)
void initializeVelocities();
//  Compute total potential energy from particle coordinates
double Potential();
//  Compute mean squared velocity from particle velocities
double MeanSquaredVelocity();
//  Compute total kinetic energy from particle mass and velocities
double Kinetic();

int main()
{

  //  variable declarations
  int i;
  double dt, Vol, Temp, Press, Pavg, Tavg;
  double rho; // gas density in moles/m^3
  /**
   * Inside the simulation, everything is expressed in units built from the
   * Lennard-Jones parameters, so that σ = ε = m = k_B = 1. The four *Fac
   * variables are the bridges back to SI: multiply a natural-unit value by its
   * factor to get SI units, and divide an SI value by it to get natural units.
   */
  double VolFac, TempFac, PressFac, timefac;
  /**
   * Z = compressibility factor
   * gc (aka R) = ideal gas universal constant
   */
  double KE, PE, mvs, gc, Z;
  char trash[10000], prefix[1000], tfn[1000], ofn[1000], afn[1000];
  FILE *infp, *tfp, *ofp, *afp;

  printf("\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  printf("                  WELCOME TO WILLY P CHEM MD!\n");
  printf("  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  printf("\n  ENTER A TITLE FOR YOUR CALCULATION!\n");
  scanf("%s", prefix);
  strcpy(tfn, prefix);
  strcat(tfn, "_traj.xyz");
  strcpy(ofn, prefix);
  strcat(ofn, "_output.txt");
  strcpy(afn, prefix);
  strcat(afn, "_average.txt");

  printf("\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  printf("                  TITLE ENTERED AS '%s'\n", prefix);
  printf("  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");

  /*     Table of values for Argon relating natural units to SI units:
   *     These are derived from Lennard-Jones parameters from the article
   *     "Liquid argon: Monte carlo and molecular dynamics calculations"
   *     J.A. Barker , R.A. Fisher & R.O. Watts
   *     Mol. Phys., Vol. 21, 657-673 (1971)
   *
   *     mass:     6.633e-26 kg       = one natural unit of mass for argon, by
   * definition energy:   1.96183e-21 J      = one natural unit of energy for
   * argon, directly from L-J parameters length:   3.3605e-10  m      = one
   * natural unit of length for argon, directly from L-J parameters
   *     volume:   3.79499-29 m^3     = one natural unit of volume for argon, by
   * length^3 time:     1.951e-12 s        = one natural unit of time for argon,
   * by length*sqrt(mass/energy)
   ***************************************************************************************/

  //  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  //  Edit these factors to be computed in terms of basic properties in natural
  //  units of the gas being simulated

  printf("\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  printf("  WHICH NOBLE GAS WOULD YOU LIKE TO SIMULATE? (DEFAULT IS ARGON)\n");
  printf("\n  FOR HELIUM,  TYPE 'He' THEN PRESS 'return' TO CONTINUE\n");
  printf("  FOR NEON,    TYPE 'Ne' THEN PRESS 'return' TO CONTINUE\n");
  printf("  FOR ARGON,   TYPE 'Ar' THEN PRESS 'return' TO CONTINUE\n");
  printf("  FOR KRYPTON, TYPE 'Kr' THEN PRESS 'return' TO CONTINUE\n");
  printf("  FOR XENON,   TYPE 'Xe' THEN PRESS 'return' TO CONTINUE\n");
  printf("  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  scanf("%s", atype);

  if (strcmp(atype, "He") == 0) {

    VolFac = 1.8399744000000005e-29;
    PressFac = 8152287.336171632;
    TempFac = 10.864459551225972;
    timefac = 1.7572698825166272e-12;

  } else if (strcmp(atype, "Ne") == 0) {

    VolFac = 2.0570823999999997e-29;
    PressFac = 27223022.27659913;
    TempFac = 40.560648991243625;
    timefac = 2.1192341945685407e-12;

  } else if (strcmp(atype, "Ar") == 0) {

    VolFac = 3.7949992920124995e-29;
    PressFac =
        51695201.06691862; // pressure = force/area(N/m^2). Since J = N*m -> N =
                           // J/m, then pressure = energy/volume (J/m^3)
    TempFac = 142.0950000000000; // T = energy/k_B
    timefac = 2.09618e-12; // TODO: why is it different from the table above?
    // strcpy(atype,"Ar");

  } else if (strcmp(atype, "Kr") == 0) {

    VolFac = 4.5882712000000004e-29;
    PressFac = 59935428.40275003;
    TempFac = 199.1817584391428;
    timefac = 8.051563913585078e-13;

  } else if (strcmp(atype, "Xe") == 0) {

    VolFac = 5.4872e-29;
    PressFac = 70527773.72794868;
    TempFac = 280.30305642163006;
    timefac = 9.018957925790732e-13;

  } else {

    VolFac = 3.7949992920124995e-29;
    PressFac = 51695201.06691862;
    TempFac = 142.0950000000000;
    timefac = 2.09618e-12;
    strcpy(atype, "Ar");
  }
  printf("\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  printf("\n                     YOU ARE SIMULATING %s GAS! \n", atype);
  printf("\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");

  printf("\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  printf("\n  YOU WILL NOW ENTER A FEW SIMULATION PARAMETERS\n");
  printf("  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
  printf("\n\n  ENTER THE INTIAL TEMPERATURE OF YOUR GAS IN KELVIN\n");
  scanf("%lf", &Tinit);
  // Make sure temperature is a positive number!
  if (Tinit < 0.) {
    printf("\n  !!!!! ABSOLUTE TEMPERATURE MUST BE A POSITIVE NUMBER!  PLEASE "
           "TRY AGAIN WITH A POSITIVE TEMPERATURE!!!\n");
    exit(0);
  }
  // Convert initial temperature from kelvin to natural units
  Tinit /= TempFac;

  printf("\n\n  ENTER THE NUMBER DENSITY IN moles/m^3\n");
  printf("  FOR REFERENCE, NUMBER DENSITY OF AN IDEAL GAS AT STP IS ABOUT 40 "
         "moles/m^3\n");
  printf("  NUMBER DENSITY OF LIQUID ARGON AT 1 ATM AND 87 K IS ABOUT 35000 "
         "moles/m^3\n");

  scanf("%lf", &rho);

  N = 5000;
  Vol = N / (rho * NA); // N/NA = moles; moles/(mol/m³) = m³
  Vol /= VolFac;        // m³ -> σ³

  //  Limiting N to MAXPART for practical reasons
  if (N >= MAXPART) {

    printf("\n\n\n  MAXIMUM NUMBER OF PARTICLES IS %i\n\n  PLEASE ADJUST YOUR "
           "INPUT FILE ACCORDINGLY \n\n",
           MAXPART);
    exit(0);
  }

  /**
   * Van der Waals (VDW) radius é a metade da distância mínima entre os núcleos
   * de dois átomos idênticos (não ligados covalentemente) quando eles estão
   * o mais próximo possível um do outro, antes que as forças repulsivas entre
   * suas nuvens eletrônicas impeçam uma aproximação maior.
   *
   */
  //  Check to see if the volume makes sense - is it too small?
  //  Remember VDW radius of the particles is 1/2 * natural unit of length
  //  and (volume) V = L*L*L, so if V = N*L*L*L = N, then all the particles
  //  will be initialized with an interparticle separation equal to 2xVDW = L (=
  //  V) radius
  if (Vol < N) {

    printf("\n\n\n  YOUR DENSITY IS VERY HIGH!\n\n");
    printf("  THE NUMBER OF PARTICLES IS %i AND THE AVAILABLE VOLUME IS %f "
           "NATURAL UNITS\n",
           N, Vol);
    printf("  SIMULATIONS WITH DENSITY GREATER THAN 1 PARTCICLE/(1 Natural "
           "Unit of Volume) MAY DIVERGE\n");
    printf("  PLEASE ADJUST YOUR INPUT FILE ACCORDINGLY AND RETRY\n\n");
    exit(0);
  }
  // Vol = L*L*L;
  // Length of the box in natural units:
  L = pow(Vol, (1. / 3));

  //  Files that we can write different quantities to
  tfp = fopen(tfn, "w"); //  The MD trajectory, coordinates of every particle at
                         //  each timestep
  ofp = fopen(
      ofn,
      "w"); //  Output of other quantities (T, P, gc, etc) at every timestep
  afp = fopen(afn, "w"); //  Average T, P, gc, etc from the simulation

  int NumTime;
  if (strcmp(atype, "He") == 0) {

    // dt in natural units of time s.t. in SI it is 5 f.s. for all other gasses
    dt = 0.2e-14 / timefac;
    //  We will run the simulation for NumTime timesteps.
    //  The total time will be NumTime*dt in natural units
    //  And NumTime*dt multiplied by the appropriate conversion factor for time
    //  in seconds
    NumTime = 50000;
  } else {
    dt = 0.5e-14 / timefac;
    NumTime = 200;
    // NumTime = 20000 // original code
  }

  //  Put all the atoms in simple crystal lattice and give them random
  //  velocities that corresponds to the initial temperature we have specified
  initialize();

  //  Based on their positions, calculate the ininial intermolecular forces
  //  The accellerations of each particle will be defined from the forces and
  //  their mass, and this will allow us to update their positions via Newton's
  //  law
  computeAccelerations();

  // Print number of particles to the trajectory file
  fprintf(tfp, "%i\n", N);

  //  We want to calculate the average Temperature and Pressure for the
  //  simulation The variables need to be set to zero initially
  Pavg = 0;
  Tavg = 0;

  int tenp = floor(NumTime / 10);
  fprintf(ofp,
          "  time (s)              T(t) (K)              P(t) (Pa)           "
          "Kinetic En. (n.u.)     Potential En. (n.u.) Total En. (n.u.)\n");
  printf("  PERCENTAGE OF CALCULATION COMPLETE:\n  [");
  for (i = 0; i < NumTime + 1; i++) {

    //  This just prints updates on progress of the calculation for the users
    //  convenience
    if (i == tenp)
      printf(" 10 |");
    else if (i == 2 * tenp)
      printf(" 20 |");
    else if (i == 3 * tenp)
      printf(" 30 |");
    else if (i == 4 * tenp)
      printf(" 40 |");
    else if (i == 5 * tenp)
      printf(" 50 |");
    else if (i == 6 * tenp)
      printf(" 60 |");
    else if (i == 7 * tenp)
      printf(" 70 |");
    else if (i == 8 * tenp)
      printf(" 80 |");
    else if (i == 9 * tenp)
      printf(" 90 |");
    else if (i == 10 * tenp)
      printf(" 100 ]\n");
    fflush(stdout);

    // This updates the positions and velocities using Newton's Laws
    // Also computes the Pressure as the sum of momentum changes from wall
    // collisions / timestep which is a Kinetic Theory of gasses concept of
    // Pressure
    Press = VelocityVerlet(dt, i + 1, tfp);
    Press *= PressFac;

    //  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //  Now we would like to calculate somethings about the system:
    //  Instantaneous mean velocity squared, Temperature, Pressure
    //  Potential, and Kinetic Energy
    //  We would also like to use the IGL to try to see if we can extract the
    //  gas constant
    mvs = MeanSquaredVelocity();
    KE = Kinetic();
    PE = Potential();

    // Temperature from Kinetic Theory
    // kB = 1.
    // m = 1.
    Temp = m * mvs / (3 * kB) * TempFac;

    // Instantaneous gas constant and compressibility - not well defined because
    // pressure may be zero in some instances because there will be zero wall
    // collisions, pressure may be very high in some instances because there
    // will be a number of collisions

    // isaias: gc value is not used until its next assignment
    gc = NA * Press * (Vol * VolFac) /
         (N * Temp); // comes from PV = nRT with n = N/N_A, solved for R

    // isaias: Z value is not used until its next assignment
    Z = Press * (Vol * VolFac) / (N * kBSI * Temp);

    Tavg += Temp;
    Pavg += Press;

    fprintf(ofp, "  %8.4e  %20.8f  %20.8f %20.8f  %20.8f  %20.8f \n",
            i * dt * timefac, Temp, Press, KE, PE, KE + PE);
  }

  // Because we have calculated the instantaneous temperature and pressure,
  // we can take the average over the whole simulation here
  Pavg /= NumTime;
  Tavg /= NumTime;
  Z = Pavg * (Vol * VolFac) / (N * kBSI * Tavg);
  gc = NA * Pavg * (Vol * VolFac) / (N * Tavg);
  fprintf(afp, "  Total Time (s)      T (K)               P (Pa)      PV/nT "
               "(J/(mol K))         Z           V (m^3)              N\n");
  fprintf(afp,
          " --------------   -----------        ---------------   "
          "--------------   ---------------   ------------   -----------\n");
  fprintf(afp,
          "  %8.4e  %15.5f       %15.5f     %10.5f       %10.5f        %10.5e  "
          "       %i\n",
          i * dt * timefac, Tavg, Pavg, gc, Z, Vol * VolFac, N);

  printf("\n  TO ANIMATE YOUR SIMULATION, OPEN THE FILE \n  '%s' WITH VMD "
         "AFTER THE SIMULATION COMPLETES\n",
         tfn);
  printf(
      "\n  TO ANALYZE INSTANTANEOUS DATA ABOUT YOUR MOLECULE, OPEN THE FILE \n "
      " '%s' WITH YOUR FAVORITE TEXT EDITOR OR IMPORT THE DATA INTO EXCEL\n",
      ofn);
  printf("\n  THE FOLLOWING THERMODYNAMIC AVERAGES WILL BE COMPUTED AND "
         "WRITTEN TO THE FILE  \n  '%s':\n",
         afn);
  printf("\n  AVERAGE TEMPERATURE (K):                 %15.5f\n", Tavg);
  printf("\n  AVERAGE PRESSURE  (Pa):                  %15.5f\n", Pavg);
  printf("\n  PV/nT (J * mol^-1 K^-1):                 %15.5f\n", gc);
  printf("\n  PERCENT ERROR of pV/nT AND GAS CONSTANT: %15.5f\n",
         100 * fabs(gc - 8.3144598) / 8.3144598);
  printf("\n  THE COMPRESSIBILITY (unitless):          %15.5f \n", Z);
  printf("\n  TOTAL VOLUME (m^3):                      %10.5e \n",
         Vol * VolFac);
  printf("\n  NUMBER OF PARTICLES (unitless):          %i \n", N);

  fclose(tfp);
  fclose(ofp);
  fclose(afp);

  return 0;
}

void initialize()
{
  int n, p, i, j, k;
  double pos;

  // Number of atoms in each direction
  n = int(ceil(pow(N, 1.0 / 3)));

  //  spacing between atoms along a given direction
  pos = L / n;

  //  index for number of particles assigned positions
  p = 0;
  //  initialize positions
  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      for (k = 0; k < n; k++) {
        if (p < N) {

          r[p][0] = (i + 0.5) * pos;
          r[p][1] = (j + 0.5) * pos;
          r[p][2] = (k + 0.5) * pos;
        }
        p++;
      }
    }
  }

  // Call function to initialize velocities
  initializeVelocities();

  /***********************************************
   *   Uncomment if you want to see what the initial positions and velocities
   are printf("  Printing initial positions!\n"); for (i=0; i<N; i++) { printf("
   %6.3e  %6.3e  %6.3e\n",r[i][0],r[i][1],r[i][2]);
   }

   printf("  Printing initial velocities!\n");
   for (i=0; i<N; i++) {
   printf("  %6.3e  %6.3e  %6.3e\n",v[i][0],v[i][1],v[i][2]);
   }
   */
}

//  Function to calculate the averaged velocity squared
double MeanSquaredVelocity()
{

  double vx2 = 0;
  double vy2 = 0;
  double vz2 = 0;
  double v2;

  for (int i = 0; i < N; i++) {
    vx2 = vx2 + v[i][0] * v[i][0];
    vy2 = vy2 + v[i][1] * v[i][1];
    vz2 = vz2 + v[i][2] * v[i][2];
  }
  v2 = (vx2 + vy2 + vz2) / N;

  // printf("  Average of x-component of velocity squared is %f\n",v2);
  return v2;
}

//  Function to calculate the kinetic energy of the system
//  Since it's a small loop, so it's not worth parallelizing it with OpenMP
double Kinetic() {

  double sum = 0.;

  for (int i = 0; i < N; i++) {
    sum += (v[i][0] * v[i][0]) + (v[i][1] * v[i][1]) + (v[i][2] * v[i][2]);
  }

  // printf("  Total Kinetic Energy is %f\n",N*mvs*m/2.);
  return 0.5 * m * sum;
}

/**
 * Function to return the calculated potential energy of the system
 * 
 * Warning:
 * 
 * The Lennard-Jones term is symmetric: V(r_ij) = V(r_ji), 
 * because the distance does not depend on the order. 
 * the original MD's Potential() function visits every (i, j) with j ≠ i, 
 * so each pair is counted twice and the total came out 2× larger.
 * 
 **/ 
double Potential() {
  return Epot;
}

static inline svfloat64_t recip(svbool_t pg, svfloat64_t d)
{
  // svrecpe_f64 = computes the reciprocal estimate of each lane of d (1/d)
  svfloat64_t x = svrecpe_f64(d);
  // svmul_f64_x (mask, op1, op2) = multiplicação elemento a elemento de dois vetores de ponto flutuante de precisão dupla 
  x = svmul_f64_x(pg, x, svrecps_f64(d, x)); // 8 -> 16
  x = svmul_f64_x(pg, x, svrecps_f64(d, x)); // 16 -> 32
  x = svmul_f64_x(pg, x, svrecps_f64(d, x)); // 32 -> 64 (full double precision)
  return x;
}

/**
 * Computes the acceleration of every particle from Lennard-Jones forces
 * and stores it in the global matrix `a`.
 *
 * Natural units (sigma = epsilon = m = 1), so a = F.
 * With R = |r_i - r_j|^2, f = 24 * (2*R^-7 - R^-4) is the LJ force divided by r, 
 * so rij * f is the force vector on i. By Newton's third law the same value
 * is added to a[i] and subtracted from a[j].
 *
 * pow() is replaced by one division and a few multiplications.
 * Cost: O(N^2). Reads r and N; overwrites a.
 *
 */

void computeAccelerations()
{
  double Pot = 0.0;

#pragma omp parallel reduction(+ : Pot)
  {

    /**
     * Originally, particle positions were stored side-by-side in memory:
     * x0, y0, z0, x1, y1, z1, ... (Array of Structures / AoS).
     * So if you grab 8 consecutive doubles, you get mixed x, y, and z values.
     * The code now copies them into three separate arrays: rx[], ry[], and rz[] 
     * (Structure of Arrays / SoA), aligned to 256 bytes (alignas(256)). 
     * Now rx[j], rx[j+1], ..., rx[j+7] sit right next to each other in memory
     * so a vector load can grab 8 x coordinates cleanly in one shot.
     */
#pragma omp for schedule(static)
    for (int i = 0; i < N; i++) {
      rx[i] = r[i][0];
      ry[i] = r[i][1];
      rz[i] = r[i][2];
    }

    // Each thread owns its particles: no shared writes, no buffers.
#pragma omp for schedule(static)
    for (int i = 0; i < N; i++) {
      // svdup_f64 = copies particle i's position into all lanes of a vector register
      const svfloat64_t xi = svdup_f64(rx[i]);
      const svfloat64_t yi = svdup_f64(ry[i]);
      const svfloat64_t zi = svdup_f64(rz[i]);
      svfloat64_t fx = svdup_f64(0.0), fy = svdup_f64(0.0);
      svfloat64_t fz = svdup_f64(0.0), pot = svdup_f64(0.0);

      // 8 values of j per iteration (64 bytes - 8 doubles vectors)
      for (int64_t j = 0; j < N; j += svcntd()) {
        // svbool_t = predicate mask for 64-bit lanes, svwhilelt_b64 = while less than
        const svbool_t pg = svwhilelt_b64(j, (int64_t)N);
        
        /**
         * svld1_f64 = loads up to 8 neighbor x coordinates starting at j
         * 
         * svsub_f64_x (mask, op1, op2) = subtrai os elementos do segundo vetor (op2) dos elementos
         * correspondentes do primeiro vetor (op1) para cada faixa (lane) ativa definida pelo predicado pg
         */
        const svfloat64_t dx = svsub_f64_x(pg, xi, svld1_f64(pg, &rx[j]));
        const svfloat64_t dy = svsub_f64_x(pg, yi, svld1_f64(pg, &ry[j]));
        const svfloat64_t dz = svsub_f64_x(pg, zi, svld1_f64(pg, &rz[j]));
        
        // svmul_f64_x (mask, op1, op2) = multiplicação elemento a elemento de dois vetores de ponto flutuante de precisão dupla 
        // computes the squared distance for each lane: d = dx*dx + dy*dy + dz*dz , for 8 j-neighbors at a time
        svfloat64_t d = svmul_f64_x(pg, dx, dx);

        // svmla_f64_x (mask, acc, op1, op2) [fused multiply-add] = acc + (op1 * op2) for each lane
        d = svmla_f64_x(pg, d, dy, dy);
        d = svmla_f64_x(pg, d, dz, dz);

        // svcmpne_n_f64 = compares each lane of d with 0.0 and sets the corresponding bit in the predicate mask ok if they are not equal
        const svbool_t ok = svcmpne_n_f64(pg, d, 0.0);

        const svfloat64_t inv = recip(ok, d);
        const svfloat64_t i3  = svmul_f64_x(ok, svmul_f64_x(ok, inv, inv), inv);
        const svfloat64_t sr6 = svmul_n_f64_x(ok, i3, sigma); // sigma = 1., so sigma^6 = 1.

        // potential term: sr6 * (sr6 - 1)
        // svmla_f64_m (mask, acc, op1, op2) [fused multiply-add and merge] = acc + (op1 * op2) for each lane where mask is true
        pot = svmla_f64_m(ok, pot, sr6, svsub_n_f64_x(ok, sr6, 1.0));

        // force/r (the factor 24 is applied once after the loop):
        // sr6 * (2*sr6 - 1) * inv
        svfloat64_t f = svmul_f64_x(ok, sr6,
                          svsub_n_f64_x(ok, svmul_n_f64_x(ok, sr6, 2.0), 1.0));
        
        f = svmul_f64_x(ok, f, inv);

        fx = svmla_f64_m(ok, fx, dx, f);
        fy = svmla_f64_m(ok, fy, dy, f);
        fz = svmla_f64_m(ok, fz, dz, f);
      }

      // svptrue_b64() = returns a predicate mask with all lanes set to true
      const svbool_t all = svptrue_b64();

      // svaddv_f64(all, fx) = adds all 8 lanes together into a single scalar number
      a[i][0] = 24.0 * svaddv_f64(all, fx);
      a[i][1] = 24.0 * svaddv_f64(all, fy);
      a[i][2] = 24.0 * svaddv_f64(all, fz);
      Pot += svaddv_f64(all, pot);
    }
  }
  Epot = 4 * epsilon * Pot;
}

/**
 *
 * What Velocity Verlet does:
 *
 * - Update r with the old a: r += v·dt + ½a·dt²
 * - Half-kick: v += ½a·dt
 * - Recompute a at the new r
 * - Second half-kick: v += ½a·dt
 * - Returns sum of dv/dt*m/A (aka Pressure) from elastic collisions with walls
 *
 * References:
 * - Uniform Acceleration Equations (https://physics.info/motion-equations/)
 * - pressure = force/area -> pressure = (m * dv/dt) / A (area)
 */
double VelocityVerlet(double dt, int iter, FILE *fp)
{
  int i, j;

  double psum = 0.;

  //  Compute accelerations from forces at current position
  // this call was removed (commented) for predagogical reasons
  // computeAccelerations();

  for (i = 0; i < N; i++) {
    for (j = 0; j < 3; j++) {
      // r = r + v*dt + a/2*dt^2 -> one of the Uniform Acceleration formulas
      r[i][j] += v[i][j] * dt + 0.5 * a[i][j] * dt * dt;

      // Half-kick: v += ½a·dt
      v[i][j] += 0.5 * a[i][j] * dt;
    }
    // printf("  %i  %6.4e   %6.4e   %6.4e\n",i,r[i][0],r[i][1],r[i][2]);
  }

  //  Update accellerations from updated positions
  computeAccelerations();

  /**
   * The loop below:
   *  1. Updates velocity with updated acceleration
   *  2. Flips velocity if particle is outside the box
   *  3. Computes pressure from wall collisions
   * 
   * Warning:
   *  The code below does not update the position of the particle after it collides with the wall,
   *  which means that the particle will be outside the box after the collision. 
   *  This can interfere with the interactions with other particles, because the distance will be
   *  larger than it should be. A possible solution is to set r[i][j] = 0. or r[i][j] = -r[i][j] after the collision.
   */
  for (i = 0; i < N; i++) {
    for (j = 0; j < 3; j++) {
      // Second half-kick: v += ½a·dt
      v[i][j] += 0.5 * a[i][j] * dt;
      
      if (r[i][j] < 0.) {
        v[i][j] *= -1.; //- elastic walls
        psum += 2 * m * fabs(v[i][j]) /
                dt; // contribution to pressure from "left" walls
      }
      if (r[i][j] >= L) {
        v[i][j] *= -1.; //- elastic walls
        psum += 2 * m * fabs(v[i][j]) /
                dt; // contribution to pressure from "right" walls
      }
    }
  }

  /* removed, uncomment to save atoms positions */
  /*for (i=0; i<N; i++) {
      fprintf(fp,"%s",atype);
      for (j=0; j<3; j++) {
          fprintf(fp,"  %12.10e ",r[i][j]);
      }
      fprintf(fp,"\n");
  }*/
  // fprintf(fp,"\n \n");

  return psum / (6 * L * L); // denominator = wall collisions in a cube (L^2 = area of a wall) * 6 walls
}

void initializeVelocities()
{

  int i, j;

  // Compute center-of-mas velocity according to the formula above
  // Para um sistema com n partículas, a velocidade do centro de massa é
  // dada pela razão entre a soma vetorial dos momentos lineares (quantidade de
  // movimento) de cada parte e a massa total do sistema i.e., vCM = (1/(N*m)) *
  // sum(m*v[i]) ; N*m = massa total do sistema, porque cada partícula tem massa
  // m
  double vCM[3] = {0, 0, 0};
  
  // sum(m*v[i]) / m * N = (1/N) * sum(x) 
  // -> m * sum(v[i]) / m * N 
  // -> sum(v[i]) / N
  for (i = 0; i < N; i++) {
    for (j = 0; j < 3; j++) {

      v[i][j] = gaussdist(); //  Pull a number from a Gaussian Distribution
      vCM[j] += v[i][j];
    }
  }

  for (i = 0; i < 3; i++){
    vCM[i] /= N;
  }

  //  Subtract out the center-of-mass velocity from the
  //  velocity of each particle... effectively set the
  //  center of mass velocity to zero so that the system does
  //  not drift in space!
  //  And compute the average velocity squared for the system, which is related to the temperature of the system
  double vSqdSum = 0.;
  for (i = 0; i < N; i++) {
    for (j = 0; j < 3; j++) {

      v[i][j] -= vCM[j];
      vSqdSum += v[i][j] * v[i][j];
    }
  }
  
  //  Equipartition: KE = 3/2 (N-1) kB T  (3 DOF removed with the CM velocity -> N-1)
  //  Now we want to scale the average velocity of the system
  //  by a factor which is consistent with our initial temperature, Tinit
  double lambda = sqrt(3 * (N - 1) * Tinit / vSqdSum);

  for (i = 0; i < N; i++) {
    for (j = 0; j < 3; j++) {

      v[i][j] *= lambda;
    }
  }
}

//  Numerical recipes Gaussian distribution number generator
double gaussdist()
{
  static bool available = false;
  static double gset;
  double fac, rsq, v1, v2;
  if (!available) {
    do {
      v1 = 2.0 * rand() / double(RAND_MAX) - 1.0;
      v2 = 2.0 * rand() / double(RAND_MAX) - 1.0;
      rsq = v1 * v1 + v2 * v2;
    } while (rsq >= 1.0 || rsq == 0.0);

    fac = sqrt(-2.0 * log(rsq) / rsq);
    gset = v1 * fac;
    available = true;

    return v2 * fac;
  } else {

    available = false;
    return gset;
  }
}
