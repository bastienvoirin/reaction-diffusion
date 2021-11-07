PGraphics top;
PGraphics mid;
PGraphics bot;
float D_A = 1.0;   
float D_B = 0.5; 
float D_T = 0.5;
float feed = 0.03; 
float kill = 0.06; 
float k = 3.1;
float E = 1.7; 
float H1 = -0.020;
float H2 =  0.025;
int grid_width = 535;
int grid_height = 200;
int grid_row;
int grid_col;
float[][][] grid = new float[535][200][5]; // $(A_1, B_1, A_2, B_2, T)$
float[][][] next = new float[535][200][5]; // $(A_1, B_1, A_2, B_2, T)$
float[][] kernel = {{0.083333,  0.166667, 0.083333},
                    {0.166667, -1.0,      0.166667},
                    {0.083333,  0.166667, 0.083333}};

// $\ce{A_1} - \ce{B_1}$ en nuances de gris
color colormap_top(float cell[]) {
  colorMode(RGB, 1.0);
  return color(cell[0]-cell[1]);
}

// Bleu ($T = \num{1}$) à rouge ($T = \num{2}$) en passant par blanc ($T = \num{1.5}$)
color colormap_mid(float cell[]) {
  colorMode(RGB, 1.0);
  float m = 1.0; // $\min(T)$, bleu
  float M = 2.0; // $\max(T)$, rouge
  float x = 2*(cell[4]-m)/(M-m); // $T$
  float r = min(1.0, x);
  float g = min(x, 2.0-x);
  float b = min(1.0, 2.0-x);
  return color(r, g, b);
}

// $\ce{A_2} - \ce{B_2}$ en nuances de gris
color colormap_bot(float cell[]) {
  colorMode(RGB, 1.0);
  return color(cell[2]-cell[3]);
}

float laplacian(int row, int col, int variable) {
  float sum = 0.0;
  for (byte i = -1; i < 2; i++) {
    for (byte j = -1; j < 2; j++) {
      grid_col = col+i;
      grid_row = row+j;
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
  size(600, 600);
  top = createGraphics(535, 200);
  mid = createGraphics(535, 200);
  bot = createGraphics(535, 200);
  top.beginDraw();
  mid.beginDraw();
  bot.beginDraw();
  surface.setTitle("Réactions endothermique et exothermique, diffusion");
  surface.setResizable(false);
  background(255);
  fill(0);
  textAlign(LEFT, CENTER);
  textSize(20);
  for (int col = 0; col < grid_width; col++) {
    for (int row = 0; row < grid_height; row++) {
      grid[col][row][0] = 1.0; // $\ce{A_1}$
      grid[col][row][2] = 1.0; // $\ce{A_2}$
      if (col > 0 && col < grid_width-1 && row > 0 && row < grid_height-1) {
        grid[col][row][1] = (random(1.0) > 0.2) ? 0.0 : 0.25; // $\ce{B_1}$
        grid[col][row][3] = (random(1.0) > 0.2) ? 0.0 : 0.25; // $\ce{B_2}$
      }
      grid[col][row][4] = 1.5; // $T$
      next[col][row][0] = grid[col][row][0];
      next[col][row][1] = grid[col][row][1];
      next[col][row][2] = grid[col][row][2];
      next[col][row][3] = grid[col][row][3];
      next[col][row][4] = grid[col][row][4];
    }
  }
  
  loadPixels();
  for (int row = 20; row < grid_height-20; row++) {
    for (int col = 540; col < 560; col++) {
      float val = float((row-20) % (grid_height-40)) / float(grid_height-40);
      float[] cell = {1.0-val, 0.0, 1.0-val, 0.0, 2.0-val};
      pixels[col + row * width]                   = colormap_top(cell);
      pixels[col + (row + grid_height) * width]   = colormap_mid(cell);
      pixels[col + (row + 2*grid_height) * width] = colormap_bot(cell);
    }
  }
  updatePixels();
  
  text("1,0", 565, 20);
  text("0,5", 565, grid_height/2);
  text("0,0", 565, grid_height-20);
  text("2,0", 565, grid_height+20);
  text("1,5", 565, 3*grid_height/2);
  text("1,0", 565, 2*grid_height-20);
  text("1,0", 565, 2*grid_height+20);
  text("0,5", 565, 5*grid_height/2);
  text("0,0", 565, 3*grid_height-20);
}

void draw() {
  top.loadPixels();
  mid.loadPixels();
  bot.loadPixels();
  for (int col = 1; col < grid_width-1; col++) {
    for (int row = 1; row < grid_height-1; row++) {
      float A1 = grid[col][row][0];
      float B1 = grid[col][row][1];
      float A2 = grid[col][row][2];
      float B2 = grid[col][row][3];
      float T  = grid[col][row][4];
      next[col][row][0] = A1 + D_A*laplacian(row, col, 0) - k*exp(-E/T)*A1*B1*B1 + feed*(1-A1);
      next[col][row][1] = B1 + D_B*laplacian(row, col, 1) + k*exp(-E/T)*A1*B1*B1 - (kill + feed)*B1;
      next[col][row][2] = A2 + D_A*laplacian(row, col, 2) - k*exp(-E/T)*A2*B2*B2 + feed*(1-A2);
      next[col][row][3] = B2 + D_B*laplacian(row, col, 3) + k*exp(-E/T)*A2*B2*B2 - (kill + feed)*B2;
      next[col][row][4] = T  + D_T*laplacian(row, col, 4) - k*exp(-E/T)*(H1*A1*B1*B1 + H2*A2*B2*B2);
      next[col][row][0] = constrain(next[col][row][0], 0.0, 1.0);
      next[col][row][1] = constrain(next[col][row][1], 0.0, 1.0);
      next[col][row][2] = constrain(next[col][row][2], 0.0, 1.0);
      next[col][row][3] = constrain(next[col][row][3], 0.0, 1.0);
    }
    next[col][0][4]             = 2.0;
    next[col][grid_height-1][4] = 2.0;
  }
  for (int row = 0; row < grid_height; row++) {
    next[0][row][4]            = 2.0;
    next[grid_width-1][row][4] = 2.0;
    for (int col = 0; col < grid_width; col++) {
      grid[col][row][0] = next[col][row][0];
      grid[col][row][1] = next[col][row][1];
      grid[col][row][2] = next[col][row][2];
      grid[col][row][3] = next[col][row][3];
      grid[col][row][4] = next[col][row][4];
      top.pixels[col + row * grid_width] = colormap_top(grid[col][row]);
      mid.pixels[col + row * grid_width] = colormap_mid(grid[col][row]);
      bot.pixels[col + row * grid_width] = colormap_bot(grid[col][row]);
    }
  }
  top.updatePixels();
  mid.updatePixels();
  bot.updatePixels();
  image(top, 0, 0);
  image(mid, 0, 200);
  image(bot, 0, 400);
  
  if (frameCount % 1000 == 0) {
    keyPressed();
  }
}

void mouseClicked() {
  int w = 16;
  int h = 16;
  for (int col = mouseX-w; col < mouseX+w; col++) {
    for (int row = mouseY%grid_height-h; row < mouseY%grid_height+h; row++) {
      if (col > 0 && col < grid_width && row > 0 && row < grid_height) {
        if (mouseButton == LEFT) {
          grid[col][row][1] = 1.0; // $\ce{B_1}$
        } else if (mouseButton == RIGHT){
          grid[col][row][3] = 1.0; // $\ce{B_2}$
        }
        next[col][row][1] = grid[col][row][1];
        next[col][row][3] = grid[col][row][3];
      }
    }
  }
}

void keyPressed() {
  saveFrame("frame-######.tif");
  saveFrame("frame-######.png");
}
