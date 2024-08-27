# Note: $PKG_* variables are inserted above this line by the build script.
# Note: $ARCHIVE  and TARGET_DIR etc variables are inserted above this line by register-base.

# For most applications this will find the folder that will be extracted from
# the tarball, but some e.g. phobius, will give you weird results.
# Check that this works as expected.
EXTRACTED_DIR_CALLED="$(basename $(tar -tf "${ARCHIVE}" | head -n 1))"

# Don't change the next 3 lines
mkdir -p "${WORKDIR}"
tar --no-same-owner --directory=${WORKDIR} -zxf "${ARCHIVE}"


#### Add your code to install here.

cp -r "${WORKDIR}/${EXTRACTED_DIR_CALLED}" "${TARGET_DIR}/src"
cd "${TARGET_DIR}/src"

pip install --no-deps --upgrade --force-reinstall --compile --prefix "${ENV_PREFIX}" .

DEEPLOC_DIR=$(python3 -c "import DeepLoc2; import os; print(os.path.dirname(DeepLoc2.__file__))" )

echo "Updating model checkpoints to new pytorch format."
for f in $(find "${DEEPLOC_DIR}" -type f -name "*.ckpt")
do
    if [ -s "${f}" ]
    then
        python -m pytorch_lightning.utilities.upgrade_checkpoint "${f}" || : 2>/dev/null
    fi
done

#nb we delete WORKDIR using a trap command in register-base.sh


# Don't change the next two lines
echo "Finished registering ${PKG_NAME}."
echo "Testing installation..."


# Add a command that uses the test dataset included with the package.
# both TEST_RESULT and TEST_RETCODE should be set.
# If you REALLY have to skip tests, set TEST_RETCODE.

# If you get a non-zero exit code, the test will fail.
cd "${WORKDIR}"

TEST_RESULT=$(deeploc2 --fasta "${TARGET_DIR}/src/test.fasta" -o "${WORKDIR}/test" --model Fast --device cpu)
TEST_RETCODE=$?
