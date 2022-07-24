/*
Copyright (c) 2021, azad prajapat
https://github.com/azadprajapat/opencv_awesome/blob/master/android/src/main/jni/native_opencv.cpp

Copyright (c) 2022, 小島 伊織 / Iori Kojima
*/

//複数の画像をパノラマ画像にstitchする
#include <opencv2/opencv.hpp>
#include <opencv2/stitching.hpp>
#include <opencv2/imgproc.hpp>

using namespace cv;
using namespace std;

struct tokens : ctype<char>
{
    tokens() : std::ctype<char>(get_table()) {}

    static std::ctype_base::mask const *get_table()
    {
        typedef std::ctype<char> cctype;
        static const cctype::mask *const_rc = cctype::classic_table();

        static cctype::mask rc[cctype::table_size];
        std::memcpy(rc, const_rc, cctype::table_size * sizeof(cctype::mask));

        rc[','] = ctype_base::space;
        rc[' '] = ctype_base::space;
        return &rc[0];
    }
};
vector<string> getpathlist(string path_string)
{
    string sub_string = path_string.substr(1, path_string.length() - 2);
    stringstream ss(sub_string);
    ss.imbue(locale(locale(), new tokens()));
    istream_iterator<std::string> begin(ss);
    istream_iterator<std::string> end;
    vector<std::string> pathlist(begin, end);
    return pathlist;
}

Mat process_stitching(vector<Mat> imgVec)
{
    Mat result = Mat();
    Stitcher::Mode mode = Stitcher::PANORAMA;
    Ptr<Stitcher> stitcher = Stitcher::create(mode);
    Stitcher::Status status = stitcher->stitch(imgVec, result);
    if (status != Stitcher::OK)
    {
        hconcat(imgVec, result);
        printf("Stitching error: %d\n", status);
    }
    else
    {
        printf("Stitching success\n");
    }

    cvtColor(result, result, COLOR_RGB2BGR);
    return result;
}

vector<Mat> convert_to_matlist(vector<string> img_list, bool isvertical)
{
    vector<Mat> imgVec;
    for (auto k = img_list.begin(); k != img_list.end(); ++k)
    {
        String path = *k;
        Mat input = imread(path);
        Mat newimage;
        // Convert to a 3 channel Mat to use with Stitcher module
        cvtColor(input, newimage, COLOR_BGR2RGB, 3);
        // Reduce the resolution for fast computation
        float scale = 1000.0f / input.rows;
        resize(newimage, newimage, Size(scale * input.rows, scale * input.cols));
        if (isvertical)
            rotate(newimage, newimage, ROTATE_90_COUNTERCLOCKWISE);
        imgVec.push_back(newimage);
    }
    return imgVec;
}

void stitch(char *inputImagePath, char *outputImagePath)
{
    string input_path_string = inputImagePath;
    vector<string> image_vector_list = getpathlist(input_path_string);
    vector<Mat> mat_list;
    mat_list = convert_to_matlist(image_vector_list, false);
    Mat result = process_stitching(mat_list);
    Mat cropped_image;
    result(Rect(0, 0, result.cols, result.rows)).copyTo(cropped_image);
    imwrite(outputImagePath, cropped_image);
}
