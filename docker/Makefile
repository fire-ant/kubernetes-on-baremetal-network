build: host release

host:
	docker build -t networkop/k8soncl -f Dockerfile . 

release:
	docker push networkop/k8soncl

go:
	GO111MODULE=off go build -o file-watcher main.go 
	docker build -t networkop/k8soncl:go -f Dockerfile.go . 
	docker push networkop/k8soncl:go