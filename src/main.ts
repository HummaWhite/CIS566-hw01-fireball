import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Cube from './geometry/Cube';
import DrawParam from './rendering/gl/DrawParam';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 7,
  color: [1, 0.7, 0.5],
  FBMAmplitude: 0.5,
  FBMFrequency: 10.0,
  FBMDisplacement: 0.6,
  FBMAmplitudeMultiplier: 0.5,
  FBMFrequencyMultiplier: 2.0,
  layer: 0.1,
  sineIntensity: 1.0,
  timeScale: 1.0,
  'Load Scene': loadScene, // A function pointer, essentially
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;
let cube : Cube;

function loadScene() {
  square = new Square(vec3.fromValues(0, 0, 0), controls.tesselations);
  square.scale = vec3.fromValues(4, 4, 4);
  square.position = vec3.fromValues(0, -1, 0);
  square.create();

  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1.0, controls.tesselations);
  icosphere.scale = vec3.fromValues(1, 1, 1);
  icosphere.position = vec3.fromValues(0, 0, 0);
  icosphere.create();
}

function getGUIColor() {
  return vec4.fromValues(controls.color[0] / 255.0, controls.color[1] / 255.0, controls.color[2] / 255.0, 1.0);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 10).step(1);
  gui.add(controls, 'FBMAmplitude', 0, 1);
  gui.add(controls, 'FBMAmplitudeMultiplier', 0, 1);
  gui.add(controls, 'FBMFrequency', 0, 20);
  gui.add(controls, 'FBMDisplacement', 0, 1);
  gui.add(controls, 'layer', 0.0, 1.0);
  gui.add(controls, 'sineIntensity', 0.0, 1.0);
  gui.add(controls, 'timeScale', 0.0, 10.0);
  gui.add(controls, 'Load Scene');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const fireballShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();

    gl.viewport(0, 0, window.innerWidth, window.innerHeight);

    renderer.clear();

    if(controls.tesselations != prevTesselations) {
      prevTesselations = controls.tesselations;
      loadScene();
    }

    let param = new DrawParam();
    param.timeScale = controls.timeScale;

    let rotation = 0.4;
    //vec3.add(cube.rotation, cube.rotation, vec3.fromValues(rotation, rotation, rotation));

    icosphere.position = vec3.fromValues(-2.5, 0, 0);

    fireballShader.setUniformFloat1("u_FBMAmplitude", controls.FBMAmplitude);
    fireballShader.setUniformFloat1("u_FBMFrequency", controls.FBMFrequency);
    fireballShader.setUniformFloat1("u_FBMAmplitudeMultiplier", controls.FBMAmplitudeMultiplier);
    fireballShader.setUniformFloat1("u_Displacement", controls.FBMDisplacement);
    fireballShader.setUniformFloat1("u_Layer", controls.layer);
    fireballShader.setUniformFloat1("u_SineIntensity", controls.sineIntensity);
    fireballShader.setUniformFloat3('u_Color1', vec3.fromValues(0.1, 0.1, 1.0));
    fireballShader.setUniformFloat3('u_Color2', vec3.fromValues(1.0, 2.0, 3.0));
    fireballShader.setUniformFloat1("u_Blend1", 1);
    fireballShader.setUniformFloat1("u_Blend2", 0);

    renderer.render(camera, fireballShader, param, [
      icosphere,
    ]);

    icosphere.position = vec3.fromValues(0, 0, 0);

    fireballShader.setUniformFloat3('u_Color1', vec3.fromValues(0.1, 1.0, 0.1));
    fireballShader.setUniformFloat3('u_Color2', vec3.fromValues(2.0, 3.0, 1.0));
    fireballShader.setUniformFloat1("u_Blend1", 0.5);
    fireballShader.setUniformFloat1("u_Blend2", 0);

    renderer.render(camera, fireballShader, param, [
      icosphere,
    ]);

    icosphere.position = vec3.fromValues(2.5, 0, 0);

    fireballShader.setUniformFloat3('u_Color1', vec3.fromValues(1.0, 0.1, 0.1));
    fireballShader.setUniformFloat3('u_Color2', vec3.fromValues(3.0, 2.0, 1.0));
    fireballShader.setUniformFloat1("u_Blend1", 1);
    fireballShader.setUniformFloat1("u_Blend2", 1);

    renderer.render(camera, fireballShader, param, [
      icosphere,
    ]);

    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
