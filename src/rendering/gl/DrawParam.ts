import { vec3, vec4, mat4, glMatrix } from 'gl-matrix';
import {gl} from '../../globals';

class DrawParam {
  noiseScale: number;
  FBMAmplitude: number;
  FBMFrequency: number;
  FBMAmplitudeMultiplier: number;
  FBMFrequencyMultiplier: number;
  FBMDisplacement: number;
  layer: number;
  sineIntensity: number;
  timeScale: number;
  center: vec3;
}

export default DrawParam;