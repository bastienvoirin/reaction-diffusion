float D_A = 1.0;
float D_B = 0.5;
float[] feed_range = {0.0,  0.08}; // $\{f(\mathrm{col}_{\min}), f(\mathrm{col}_{\max})\}$
float[] kill_range = {0.02, 0.07}; // $\{k(\mathrm{row}_{\min}), k(\mathrm{row}_{\min})\}$
float[][][] grid;
float[][][] next;
float[][] kernel = {{0.083333,  0.166667, 0.083333},
                    {0.166667, -1.0,      0.166667},
                    {0.083333,  0.166667, 0.083333}};
int grid_col;
int grid_row;
                    
color colormap(float cell[]) {
  colorMode(HSB, 1.0);
  return color(240.0/360.0*(cell[0]-cell[1]), 1.0, 1.0);
}

float kill(int col) { // Axe $x$
  return lerp(kill_range[0], kill_range[1], float(col)/width);
}

float feed(int row) { // Axe $y$
  return lerp(feed_range[0], feed_range[1], float(height-1-row)/height);
}

float laplacian(int row, int col, int variable) {
  float sum = 0.0;
  for (byte i = -1; i < 2; i++) {
    for (byte j = -1; j < 2; j++) {
      grid_col = col+i;
      grid_row = row+j;
      
      // Conditions aux limites de Neumann : dérivée nulle sur les bords
      if (grid_col < 0)       grid_col = 0;
      if (grid_col >= width)  grid_col = width-1;
      if (grid_row < 0)       grid_row = 0;
      if (grid_row >= height) grid_row = height-1; 
                       
      sum += kernel[i+1][j+1] * grid[grid_col][grid_row][variable];
    }
  }
  return sum;
}

void setup() {
  size(1000, 1000);
  background(0);
  surface.setTitle("Réaction-diffusion : modèle de Gray-Scott");
  surface.setResizable(false);
  grid = new float[width][height][2];
  next = new float[width][height][2];
  
  // Conditions initiales :
  for (int col = 0; col < width; col++) {
    for (int row = 0; row < height; row++) {
      grid[col][row][0] = 1.0;
      grid[col][row][1] = (random(1.0) > 0.2) ? 0.0 : 0.5;
      next[col][row][0] = grid[col][row][0];
      next[col][row][1] = grid[col][row][1];
    }
  }
}

void draw() {
  background(0);
  
  for (int col = 0; col < width; col++) {
    for (int row = 0; row < height; row++) {
      float A = grid[col][row][0];
      float B = grid[col][row][1];
      next[col][row][0] = A + D_A*laplacian(row, col, 0) - A*B*B + feed(row)*(1 - A);
      next[col][row][1] = B + D_B*laplacian(row, col, 1) + A*B*B - (kill(col) + feed(row))*B;
      next[col][row][0] = constrain(next[col][row][0], 0.0, 1.0);
      next[col][row][1] = constrain(next[col][row][1], 0.0, 1.0);
    }
  }
  
  loadPixels();
  for (int col = 0; col < width; col++) {
    for (int row = 0; row < height; row++) {
      pixels[col + row * width] = colormap(next[col][row]);
      grid[col][row][0] = next[col][row][0];
      grid[col][row][1] = next[col][row][1];
    }
  }
  updatePixels();
  
  if (frameCount % 1000 == 0) {
    mouseClicked();
  }
}

void mouseClicked() {
  saveFrame("frame-######.tif");
  saveFrame("frame-######.png");
}
