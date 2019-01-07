//
//  ViewController.m
//  DracoDemo
//
//  Created by Caldremch on 2019/1/4.
//  Copyright © 2019 Caldremch. All rights reserved.
//
#include <cinttypes>
#include <fstream>
#import "ViewController.h"
//#include "decode.h"
//#include "cycle_timer.h"
//#include "obj_encoder.h"
//#include "parser_utils.h"
//#include "ply_encoder.h"
//#include <draco/compression/decode.h>
//#include <draco/core/cycle_timer.h>
//#include <draco/io/obj_encoder.h>
#include <draco/io/ply_encoder.h>
#include <draco/compression/decode.h>
#include <draco/core/cycle_timer.h>
#include <draco/io/obj_encoder.h>
#include <draco/io/parser_utils.h>
#include <draco/io/ply_encoder.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // 数组写入文件
    // 创建一个存储数组的文件路径
    
    // 获取文件路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"drc"];
    
//NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    
    std::ifstream input_file([filePath UTF8String], std::ios::binary);
    if (!input_file) {
        printf("Failed opening the input file.\n");
    }

    
    // Read the file stream into a buffer.
    std::streampos file_size = 0;
    input_file.seekg(0, std::ios::end);
    file_size = input_file.tellg() - file_size;
    input_file.seekg(0, std::ios::beg);
    std::vector<char> data(file_size);
    input_file.read(data.data(), file_size);
    
    if (data.empty()) {
        printf("Empty input file.\n");
       
    }

//    / Create a draco decoding buffer. Note that no data is copied in this step.
    draco::DecoderBuffer buffer;
    buffer.Init(data.data(), data.size());
    
    draco::CycleTimer timer;
    // Decode the input data into a geometry.
    std::unique_ptr<draco::PointCloud> pc;
    draco::Mesh *mesh = nullptr;
    auto type_statusor = draco::Decoder::GetEncodedGeometryType(&buffer);
    if (!type_statusor.ok()) {
         printf("type_statusor error \n");
    }
    const draco::EncodedGeometryType geom_type = type_statusor.value();
    if (geom_type == draco::TRIANGULAR_MESH) {
        timer.Start();
        draco::Decoder decoder;
        auto statusor = decoder.DecodeMeshFromBuffer(&buffer);
        if (!statusor.ok()) {
             printf("tdecoder.DecodeMeshFromBuffer(&buffer); error \n");
        }
        std::unique_ptr<draco::Mesh> in_mesh = std::move(statusor).value();
        timer.Stop();
        if (in_mesh) {
            mesh = in_mesh.get();
            pc = std::move(in_mesh);
        }
    } else if (geom_type == draco::POINT_CLOUD) {
        // Failed to decode it as mesh, so let's try to decode it as a point cloud.
        timer.Start();
        draco::Decoder decoder;
        auto statusor = decoder.DecodePointCloudFromBuffer(&buffer);
        if (!statusor.ok()) {
            printf("decoder.DecodePointCloudFromBuffer(&buffer); error \n");
        }
        pc = std::move(statusor).value();
        timer.Stop();
    }
    
    if (pc == nullptr) {
        printf("Failed to decode the input file.\n");
    }

    // Save the decoded geometry into a file.
    // TODO(ostava): Currently only .ply and .obj are supported.
    const std::string extension = draco::parser::ToLower(".obj");
    
    
    
    ///存储文件
    // 获取Caches目录
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *asd = [NSString stringWithFormat:@"%@%@",cachesPath,@"caldremch_succ_ply.obj"];
    
    const char* op = [asd UTF8String];
                     
    
    const std::string outPutFilePath = op;

    
    if (extension == ".obj") {
        draco::ObjEncoder obj_encoder;
        if (mesh) {
            if (!obj_encoder.EncodeToFile(*mesh,outPutFilePath)) {
                printf("Failed to store the decoded mesh as OBJ.\n");
            
            }
        } else {
            if (!obj_encoder.EncodeToFile(*pc.get(),outPutFilePath)) {
                printf("Failed to store the decoded point cloud as OBJ.\n");
           
            }
        }
    } else if (extension == ".ply") {
        draco::PlyEncoder ply_encoder;
        if (mesh) {
            if (!ply_encoder.EncodeToFile(*mesh,outPutFilePath)) {
                printf("Failed to store the decoded mesh as PLY.\n");
              
            }
        } else {
            if (!ply_encoder.EncodeToFile(*pc.get(),outPutFilePath)) {
                printf("Failed to store the decoded point cloud as PLY.\n");
            }
        }
    } else {
        printf("Invalid extension of the output file. Use either .ply or .obj\n");
    
    }
    printf("Decoded geometry saved to %s (%" PRId64 " ms to decode)\n",
           "options.output.c_str()", timer.GetInMs());
    
    
 
}


@end
