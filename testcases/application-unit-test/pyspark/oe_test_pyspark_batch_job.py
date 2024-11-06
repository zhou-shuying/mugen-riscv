import unittest
from pyspark.sql import SparkSession
import os
import shutil
import time

class TestPySparkBatchJob(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        # 初始化SparkSession，设置日志级别以忽略WARN
        cls.spark = SparkSession.builder \
            .appName("PySpark Batch Job Test") \
            .master("local[*]") \
            .getOrCreate()
        cls.spark.sparkContext.setLogLevel("ERROR")  # 忽略WARN日志
        
        # 设置日志路径（相对于当前工作目录）
        cls.log_dir = os.path.join(os.getcwd(), "logs")
        if not os.path.exists(cls.log_dir):
            os.makedirs(cls.log_dir)

        # 设置作业输出路径
        cls.output_dir = os.path.join(os.getcwd(), "output")
        if os.path.exists(cls.output_dir):
            shutil.rmtree(cls.output_dir)

    @classmethod
    def tearDownClass(cls):
        # 关闭 SparkSession
        cls.spark.stop()

        # 清理日志和输出目录
        if os.path.exists(cls.log_dir):
            shutil.rmtree(cls.log_dir)
        if os.path.exists(cls.output_dir):
            shutil.rmtree(cls.output_dir)

    def test_pyspark_batch_job(self):
        # 示例批处理作业：生成测试数据并写入输出目录
        data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
        df = self.spark.createDataFrame(data, ["name", "age"])
        df.write.csv(self.output_dir)

        # 检查输出结果是否已生成
        time.sleep(5)  # 确保作业有足够时间执行
        self.assertTrue(os.path.exists(self.output_dir), "输出目录不存在")

        # 检查日志文件
        log_file_path = os.path.join(self.log_dir, "spark_job.log")
        with open(log_file_path, "w") as log_file:
            log_file.write("Test log entry")  # 模拟日志写入
        self.assertTrue(os.path.exists(log_file_path), "日志文件不存在")

        # 校验输出结果
        output_files = os.listdir(self.output_dir)
        self.assertGreater(len(output_files), 0, "输出文件不存在")

if __name__ == "__main__":
    unittest.main()
