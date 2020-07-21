VERSION :=v1.0.20200720-stand-alone
build:

	sudo docker build -t bigdata/bigdata-16.04-spark-2.4.0-hadoop-2.7:$(VERSION)  .
	sudo docker push bigdata/bigdata-16.04-spark-2.4.0-hadoop-2.7:$(VERSION)
