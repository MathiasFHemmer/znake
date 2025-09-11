const rl = @import("raylib");

pub fn drawCubeWiresV(position: rl.Vector3, size: rl.Vector3, rotation: rl.Quaternion, color: rl.Color) void {
    drawCubeWires(position, size.x, size.y, size.z, rotation, color);
}

pub fn drawCubeWires(position: rl.Vector3, width: f32, height: f32, length: f32, rotation: rl.Quaternion, color: rl.Color) void {
    const x: f32 = 0.0;
    const y: f32 = 0.0;
    const z: f32 = 0.0;
    const rot = rotation.toMatrix().toFloatV();
    rl.gl.rlPushMatrix();
    rl.gl.rlTranslatef(position.x, position.y, position.z);
    rl.gl.rlMultMatrixf(&rot.v);

    rl.gl.rlBegin(rl.gl.rl_lines);
    rl.gl.rlColor4ub(color.r, color.g, color.b, color.a);

    // Front face
    //------------------------------------------------------------------
    // Bottom line
    rl.gl.rlVertex3f(x - width / 2.0, y - height / 2.0, z + length / 2.0); // Bottom left
    rl.gl.rlVertex3f(x + width / 2.0, y - height / 2.0, z + length / 2.0); // Bottom right

    // Left line
    rl.gl.rlVertex3f(x + width / 2.0, y - height / 2.0, z + length / 2.0); // Bottom right
    rl.gl.rlVertex3f(x + width / 2.0, y + height / 2.0, z + length / 2.0); // Top right

    // Top line
    rl.gl.rlVertex3f(x + width / 2.0, y + height / 2.0, z + length / 2.0); // Top right
    rl.gl.rlVertex3f(x - width / 2.0, y + height / 2.0, z + length / 2.0); // Top left

    // Right line
    rl.gl.rlVertex3f(x - width / 2.0, y + height / 2.0, z + length / 2.0); // Top left
    rl.gl.rlVertex3f(x - width / 2.0, y - height / 2.0, z + length / 2.0); // Bottom left

    // Back face
    //------------------------------------------------------------------
    // Bottom line
    rl.gl.rlVertex3f(x - width / 2.0, y - height / 2.0, z - length / 2.0); // Bottom left
    rl.gl.rlVertex3f(x + width / 2.0, y - height / 2.0, z - length / 2.0); // Bottom right

    // Left line
    rl.gl.rlVertex3f(x + width / 2.0, y - height / 2.0, z - length / 2.0); // Bottom right
    rl.gl.rlVertex3f(x + width / 2.0, y + height / 2.0, z - length / 2.0); // Top right

    // Top line
    rl.gl.rlVertex3f(x + width / 2.0, y + height / 2.0, z - length / 2.0); // Top right
    rl.gl.rlVertex3f(x - width / 2.0, y + height / 2.0, z - length / 2.0); // Top left

    // Right line
    rl.gl.rlVertex3f(x - width / 2.0, y + height / 2.0, z - length / 2.0); // Top left
    rl.gl.rlVertex3f(x - width / 2.0, y - height / 2.0, z - length / 2.0); // Bottom left

    // Top face
    //------------------------------------------------------------------
    // Left line
    rl.gl.rlVertex3f(x - width / 2.0, y + height / 2.0, z + length / 2.0); // Top left front
    rl.gl.rlVertex3f(x - width / 2.0, y + height / 2.0, z - length / 2.0); // Top left back

    // Right line
    rl.gl.rlVertex3f(x + width / 2.0, y + height / 2.0, z + length / 2.0); // Top right front
    rl.gl.rlVertex3f(x + width / 2.0, y + height / 2.0, z - length / 2.0); // Top right back

    // Bottom face
    //------------------------------------------------------------------
    // Left line
    rl.gl.rlVertex3f(x - width / 2.0, y - height / 2.0, z + length / 2.0); // Top left front
    rl.gl.rlVertex3f(x - width / 2.0, y - height / 2.0, z - length / 2.0); // Top left back

    // Right line
    rl.gl.rlVertex3f(x + width / 2.0, y - height / 2.0, z + length / 2.0); // Top right front
    rl.gl.rlVertex3f(x + width / 2.0, y - height / 2.0, z - length / 2.0); // Top right back
    rl.gl.rlEnd();
    rl.gl.rlPopMatrix();
}
